package ru.aleshi.letsplaycities.social

import androidx.annotation.StringRes
import ru.aleshi.letsplaycities.R

enum class Achievement constructor(
        @StringRes val res: Int,
        val isIncremental: Boolean = false,
        val scaleFactor: Int = 1
) {
    Write15Cities(R.string.ach_write_15c, true),

    Use3Tips(R.string.ach_tips_3, true),

    Add1Friend(R.string.ach_friend_1),

    PlayInHardMode(R.string.ach_hard_mode),

    ReachScore1000Pts(R.string.ach_score_1000, true),

    Write80Cities(R.string.ach_write_80c, true),

    LoginViaSocial(R.string.ach_social),

    ChangeTheme(R.string.ach_theme),

    Write50CitiesInGame(R.string.ach_30c_in_game),

    PlayOnline3Times(R.string.ach_online_3_times, true),

    Use30Tips(R.string.ach_tips_30, true),

    ReachScore5000Pts(R.string.ach_score_5000, true),

    Write500Cities(R.string.ach_write_500c, true),

    Write100CitiesInGame(R.string.ach_100c_in_game),

    ReachScore25000Pts(R.string.ach_score_25000, true, 6);
}