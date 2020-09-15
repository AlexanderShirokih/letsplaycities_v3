package ru.aleshi.lets_play_cities;

import android.annotation.SuppressLint;
import android.content.SharedPreferences;
import android.util.Base64;

import androidx.annotation.NonNull;

import java.util.ArrayList;

/**
 * Checks there is previous versions was installed in creates new shared preferences file
 */
public class MigrationHelper {

    public static void runMigrationIfNeeded(SharedPreferences old, SharedPreferences current) {
        if (!isShouldRunMigration(old)) {
            final GamePreferences prefs = loadOldPrefs(old);
            saveNewPrefs(prefs, current);
            removeOldPrefs(old);
        }
    }

    private static boolean isShouldRunMigration(@NonNull SharedPreferences old) {
        return old.getBoolean("first_launch", true);
    }

    private static void removeOldPrefs(@NonNull SharedPreferences prefs) {
        prefs.edit().clear().apply();
    }

    private static GamePreferences loadOldPrefs(@NonNull SharedPreferences old) {
        return new GamePreferences(
                old.getInt("gamediff", 0),
                old.getInt("speller", 0) == 1,
                old.getInt("sound", 0) == 1,
                old.getInt("rec_msg", 0) == 1,
                getTimerValue(old.getInt("timer", 0)),
                old.getInt("scoring_sys", 0),
                getScoring(old.getString("scrbkey", null)),
                old.getLong("last_upd_date", 0),
                getDictionaryUpdatePeriod(old.getInt("dic_upd", 0)),
                old.getBoolean("first_launch", true)
        );
    }

    private static String getScoring(String encoded) {
        return encoded == null ? "" :
                encodeBase64(convertFromLegacyToJson(decodeBase64(encoded)));
    }

    private static int getTimerValue(int timer) {
        return timer == 0 ? timer : (timer * 2 - 1) * 60;
    }

    private static int getDictionaryUpdatePeriod(int dictionaryUpdatePeriod) {
        switch (dictionaryUpdatePeriod) {
            case 0:
                return 1;
            case 1:
                return 2;
            default:
                return 0;
        }
    }

    private static String decodeBase64(String encoded) {
        return new String(Base64.decode(encoded, Base64.DEFAULT));
    }

    private static String encodeBase64(@NonNull String decoded) {
        return Base64.encodeToString(decoded.getBytes(), Base64.NO_WRAP);
    }

    private static String convertFromLegacyToJson(@NonNull String scoring) {
        final StringBuilder buffer = new StringBuilder();
        buffer.append("{\"scoringGroups\":[");

        final String[] split = scoring.split(",");
        for (int i = 0; i < split.length; i++) {
            buffer.append('{');

            final String group = split[i];
            final String main = group.substring(0, group.indexOf('<'));

            final ArrayList<ScoringField> child = new ArrayList<>();
            for (String c : group
                    .substring(group.indexOf('<') + 1, group.indexOf('>'))
                    .split("\\|")
            ) {
                child.add(parseField(c));
            }

            buffer.append("\"main\":").append(parseField(main).asJsonString());

            if (!child.isEmpty()) {
                buffer.append(",\"child\":[");

                for (int j = 0; j < child.size(); j++) {
                    final ScoringField field = child.get(j);
                    buffer.append(field.asJsonString());
                    if (j != child.size() - 1)
                        buffer.append(',');
                }
                buffer.append("]");
            }

            buffer.append("}");
            if (i != split.length - 1)
                buffer.append(',');
        }

        buffer.append("]}");
        return buffer.toString();
    }

    private static ScoringField parseField(@NonNull String data) {
        final String[] split = data.split("=");

        switch (split.length) {
            case 1:
                return new ScoringField("empty", split[0], null, null);
            case 2:
                try {
                    return new ScoringField(
                            split[0].equals("tim") ? "time" : "int",
                            split[0],
                            null,
                            Integer.parseInt(split[1])
                    );
                } catch (NumberFormatException e) {
                    return new ScoringField(
                            "paired",
                            split[0],
                            split[1],
                            split[0].startsWith("pval")
                                    ? Integer.parseInt(split[0].substring(split[0].length() - 1))
                                    : null);
                }
            case 3:
                return new ScoringField("paired", split[0], split[1], split[2]);
            default:
                throw new IllegalArgumentException("Bad state!");
        }
    }

    @SuppressLint("ApplySharedPref")
    private static void saveNewPrefs(@NonNull GamePreferences gamePrefs, @NonNull SharedPreferences sp) {
        sp.edit()
                .putBoolean("flutter.migrated", true)
                .putBoolean("flutter.correctionEnabled", gamePrefs.correctionEnabled)
                .putBoolean("flutter.onlineChatEnabled", gamePrefs.onlineChatEnabled)
                .putBoolean("flutter.soundEnabled", gamePrefs.soundEnabled)
                .putBoolean("flutter.firstLaunch", gamePrefs.isFirstLaunch)
                .putLong("flutter.wordsDifficulty", gamePrefs.wordsDifficulty)
                .putLong("flutter.timeLimit", gamePrefs.timeLimit)
                .putLong("flutter.scoringType", gamePrefs.scoringType)
                .putLong("flutter.dictionaryUpdatePeriod", gamePrefs.dictionaryUpdatePeriod)
                .putLong("flutter.lastDictionaryCheckDate", gamePrefs.lastDictionaryCheckDate)
                .putString("flutter.scoringData", gamePrefs.scoringData)
                .commit(); // Flush to storage immediately
    }

    private static class ScoringField {
        private final String type;
        private final String name;
        private final String key;
        private final Object value;

        ScoringField(String type, String name, String key, Object value) {
            this.type = type;
            this.name = name;
            this.key = key;
            this.value = value;
        }

        String asJsonString() {
            final String base = "\"type\": \"" + type + "\", \"name\": \"" + name + "\"";
            String additional;
            switch (type) {
                case "int":
                case "time":
                    additional = ", \"value\": " + value;
                    break;
                case "paired":
                    if (value == null)
                        additional = ", \"key\": \"" + key + "\"";
                    else
                        additional = ", \"key\": \"" + key + "\", \"value\": " + value;
                    break;
                default:
                    additional = "";
            }

            return "{" + base + additional + "}";
        }
    }

    private static class GamePreferences {
        /// Words difficulty level. (0-2)
        final int wordsDifficulty;

        /// `true` when words spelling correction is enabled.
        final boolean correctionEnabled;

        /// `true` when game sound is enabled.
        final boolean soundEnabled;

        /// `true` when chat in network mode is enabled.
        final boolean onlineChatEnabled;

        /// Time limit per users move in local game modes.
        /// `0` means timer is disabled. Measured in seconds.
        final int timeLimit;

        /// Defines game score calculation and winner checking strategy.
        /// 0 - by score, 1 - by surrender, 2- by time
        final int scoringType;

        /// Returns string containing JSON-encoded representation of score data.
        final String scoringData;

        /// Last dictionary updates checking date.
        final long lastDictionaryCheckDate;

        /// Gets dictionary update checking interval.
        /// 0 - never, 1 - every three hours, 2 - daily
        final int dictionaryUpdatePeriod;

        /// Is there a first launch
        final boolean isFirstLaunch;

        private GamePreferences(
                int wordsDifficulty,
                boolean correctionEnabled,
                boolean soundEnabled,
                boolean onlineChatEnabled,
                int timeLimit,
                int scoringType,
                String scoringData,
                long lastDictionaryCheckDate,
                int dictionaryUpdatePeriod,
                boolean isFirstLaunch
        ) {
            this.wordsDifficulty = wordsDifficulty;
            this.correctionEnabled = correctionEnabled;
            this.soundEnabled = soundEnabled;
            this.onlineChatEnabled = onlineChatEnabled;
            this.timeLimit = timeLimit;
            this.scoringType = scoringType;
            this.scoringData = scoringData;
            this.lastDictionaryCheckDate = lastDictionaryCheckDate;
            this.dictionaryUpdatePeriod = dictionaryUpdatePeriod;
            this.isFirstLaunch = isFirstLaunch;
        }
    }
}
