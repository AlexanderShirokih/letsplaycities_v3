import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/base/users.dart';

Player _player() => Player(
  LocalAccountInfo(name: 'player', picture: const PlaceholderPictureSource()),
);

/// A user who is not the local player: Android or a remote opponent.
class _Opponent extends User {
  _Opponent()
    : super(
        accountInfo: const LocalAccountInfo(
          name: 'opponent',
          picture: PlaceholderPictureSource(),
        ),
        comboSystem: ComboSystem(canUseQuickTime: false),
        isTrusted: true,
      );

  @override
  Future<String> onCreateWord(String firstChar) => throw UnimplementedError();
}

class _Prefs extends Fake implements GamePreferences {
  @override
  String scoringData;

  @override
  ScoringType scoringType;

  _Prefs({this.scoringData = '', this.scoringType = ScoringType.byScore});

  ScoringSet get stored => ScoringSet.fromJson(jsonDecode(scoringData));
}

ScoreController _controller(
  ScoringSet set, {
  ScoringType? type,
  GameMode mode = GameMode.playerVsAndroid,
}) => ScoreController(set, type ?? ScoringType.byScore, mode, (_) {});

Map<String, int?> _entries(ScoringSet set, String group) => {
  for (final field in set[group].child.cast<PairedScoringField<String, int>>())
    field.key ?? '': field.value,
};

int? _int(ScoringSet set, String group, String field) =>
    set[group][field].asIntField().value;

GameResult _result(
  User owner, {
  MatchResult matchResult = MatchResult.win,
  bool hasScore = true,
}) => GameResult(
  owner: owner,
  matchResult: matchResult,
  finishType: MoveFinishType.surrender,
  hasScore: hasScore,
  finishRequester: owner,
);

void main() {
  group('BY_TIME scoring', () {
    int pointsFor(int moveTimeMs) {
      final player = _player();
      _controller(
        ScoringSet.initial(),
        type: ScoringType.byTime,
      ).onMoveFinished(player, 'москва', moveTimeMs, const {});
      return player.score;
    }

    test('adds the 2-point base to the speed bonus', () {
      expect(pointsFor(0), 22);
      expect(pointsFor(1000), 21);
      expect(pointsFor(39000), 2);
    });

    test('never gives fewer than 2 points for a slow move', () {
      expect(pointsFor(41000), 2);
      expect(pointsFor(42500), 2);
      expect(pointsFor(43900), 2);
      expect(pointsFor(90000), 2);
    });
  });

  group('move points', () {
    /// A player whose last three cities were short: SHORT_WORD, x1.5.
    Player playerWithCombo() {
      final player = _player();
      for (var i = 0; i < 3; i++) {
        player.comboSystem.addCity(
          CityComboInfo.fromMoveParams(10000, 'ухта', 0),
        );
      }
      return player;
    }

    test('BY_SCORE gives one point per letter', () {
      final player = _player();

      _controller(ScoringSet.initial())
          .onMoveFinished(player, 'москва', 1000, const {});

      expect(player.score, 6);
    });

    test('BY_SCORE multiplies the points by the combos', () {
      final player = playerWithCombo();

      _controller(ScoringSet.initial())
          .onMoveFinished(player, 'анапа', 1000, const {});

      // 5 letters x 1.5, rounded down.
      expect(player.score, 7);
    });

    test('LAST_MOVE gives no points, even with a combo', () {
      final player = playerWithCombo();

      _controller(
        ScoringSet.initial(),
        type: ScoringType.lastMove,
      ).onMoveFinished(player, 'москва', 1000, const {});

      expect(player.score, 0);
    });

    test('the opponent scores but leaves the player\'s records alone', () {
      final set = ScoringSet.initial();
      final opponent = _Opponent();

      _controller(set).onMoveFinished(opponent, 'москва', 1000, {
        ComboType.shortWord.index: 3,
      });

      expect(opponent.score, 6);
      expect(set, ScoringSet.initial());
    });
  });

  group('online time', () {
    test('counts whole seconds of every move in a network game', () {
      final set = ScoringSet.initial();
      final controller = _controller(set, mode: GameMode.network);

      controller.onMoveFinished(_player(), 'москва', 2999, const {});
      controller.onMoveFinished(_Opponent(), 'анапа', 61500, const {});

      expect(_int(set, groupOnline, fieldTime), 63);
    });

    test('is not counted in other game modes', () {
      for (final mode in [
        GameMode.playerVsAndroid,
        GameMode.playerVsPlayer,
        GameMode.multiplayer,
      ]) {
        final set = ScoringSet.initial();

        _controller(
          set,
          mode: mode,
        ).onMoveFinished(_player(), 'москва', 30000, const {});

        expect(_int(set, groupOnline, fieldTime), 0, reason: '$mode');
      }
    });
  });

  group('combo records', () {
    test('each combo type has its own record', () {
      const fieldByType = {
        ComboType.quickTime: fieldQuickTime,
        ComboType.shortWord: fieldShortWord,
        ComboType.longWord: fieldLongWord,
        ComboType.sameCountry: fieldSameCountry,
        ComboType.differentCountries: fieldDiffCountry,
      };
      expect(fieldByType.keys, containsAll(ComboType.values));

      for (final type in ComboType.values) {
        final set = ScoringSet.initial();

        _controller(set)
            .onMoveFinished(_player(), 'москва', 1000, {type.index: 2});

        for (final field in fieldByType.values) {
          expect(
            _int(set, groupCombo, field),
            field == fieldByType[type] ? 2 : 0,
            reason: '$type: $field',
          );
        }
      }
    });

    test('keep the best level reached', () {
      final set = ScoringSet.initial();
      final controller = _controller(set);
      final player = _player();
      final quick = ComboType.quickTime.index;
      final short = ComboType.shortWord.index;

      controller.onMoveFinished(player, 'ухта', 1000, {quick: 2, short: 1});
      controller.onMoveFinished(player, 'ухта', 1000, {quick: 1, short: 3});

      expect(_int(set, groupCombo, fieldQuickTime), 2);
      expect(_int(set, groupCombo, fieldShortWord), 3);
    });
  });

  group('finished games', () {
    test('count a game for its mode', () {
      const fieldByMode = {
        GameMode.playerVsAndroid: fieldAndroid,
        GameMode.playerVsPlayer: fieldPlayer,
        GameMode.multiplayer: fieldNetwork,
        GameMode.network: fieldOnline,
      };
      expect(fieldByMode.keys, containsAll(GameMode.values));

      for (final mode in GameMode.values) {
        final set = ScoringSet.initial();
        final owner = _player()..increaseScore(10);

        _controller(set, mode: mode).onGameFinished(_result(owner));

        expect(set[groupParts].main.asIntField().value, 1, reason: '$mode');
        for (final field in fieldByMode.values) {
          expect(
            _int(set, groupParts, field),
            field == fieldByMode[mode] ? 1 : 0,
            reason: '$mode: $field',
          );
        }
      }
    });

    test('scored games ending with no points are not counted', () {
      final set = ScoringSet.initial();
      final controller = _controller(set, mode: GameMode.network);

      controller.onGameFinished(_result(_player()));

      expect(set, ScoringSet.initial());
    });

    test('are counted in LAST_MOVE games, where nobody has points', () {
      for (final mode in GameMode.values) {
        final set = ScoringSet.initial();

        _controller(
          set,
          type: ScoringType.lastMove,
          mode: mode,
        ).onGameFinished(_result(_player(), hasScore: false));

        expect(set[groupParts].main.asIntField().value, 1, reason: '$mode');
      }
    });

    test('count online wins and losses in LAST_MOVE games', () {
      final set = ScoringSet.initial();
      final controller = _controller(
        set,
        type: ScoringType.lastMove,
        mode: GameMode.network,
      );
      final owner = _player();

      controller.onGameFinished(
        _result(owner, matchResult: MatchResult.win, hasScore: false),
      );
      controller.onGameFinished(
        _result(owner, matchResult: MatchResult.lose, hasScore: false),
      );
      controller.onGameFinished(
        _result(owner, matchResult: MatchResult.lose, hasScore: false),
      );

      expect(_int(set, groupOnline, fieldWins), 1);
      expect(_int(set, groupOnline, fieldLose), 2);
      expect(_int(set, groupParts, fieldOnline), 3);
    });

    test('count online wins and losses', () {
      final set = ScoringSet.initial();
      final controller = _controller(set, mode: GameMode.network);
      final owner = _player()..increaseScore(10);

      controller.onGameFinished(_result(owner, matchResult: MatchResult.win));
      controller.onGameFinished(_result(owner, matchResult: MatchResult.win));
      controller.onGameFinished(_result(owner, matchResult: MatchResult.lose));
      controller.onGameFinished(_result(owner, matchResult: MatchResult.draw));

      expect(_int(set, groupOnline, fieldWins), 2);
      expect(_int(set, groupOnline, fieldLose), 1);
      expect(_int(set, groupParts, fieldOnline), 4);
    });

    test('count no online wins in other modes', () {
      final set = ScoringSet.initial();

      _controller(
        set,
        mode: GameMode.multiplayer,
      ).onGameFinished(_result(_player()..increaseScore(10)));

      expect(_int(set, groupOnline, fieldWins), 0);
      expect(_int(set, groupOnline, fieldLose), 0);
    });
  });

  group('most frequent cities', () {
    test('counts repeated cities', () {
      final set = ScoringSet.initial();
      final controller = _controller(set);
      final player = _player();

      for (var i = 0; i < 3; i++) {
        controller.onMoveFinished(player, 'москва', 1000, const {});
      }
      controller.onMoveFinished(player, 'анапа', 1000, const {});

      expect(_entries(set, groupFrequentCities), {'москва': 3, 'анапа': 1});
    });

    test('lets a new city into a full list', () {
      final set = ScoringSet.initial();
      final controller = _controller(set);
      final player = _player();

      for (var i = 0; i < 10; i++) {
        controller.onMoveFinished(player, 'город$i', 1000, const {});
      }
      for (var i = 0; i < 3; i++) {
        controller.onMoveFinished(player, 'новый', 1000, const {});
      }

      final entries = _entries(set, groupFrequentCities);
      expect(entries.length, 10);
      expect(entries['новый'], 3);
      expect(set[groupFrequentCities].child.first.asString(), 'новый');
    });
  });

  group('longest cities', () {
    test('ranks a longer city first when the list is full', () {
      final set = ScoringSet.initial();
      final controller = _controller(set);
      final player = _player();

      for (var i = 2; i < 12; i++) {
        controller.onMoveFinished(player, 'а' * i, 1000, const {});
      }
      const longest = 'оченьдлинноеназваниегорода';
      controller.onMoveFinished(player, longest, 1000, const {});

      final fields = set[groupBigCities].child
          .cast<PairedScoringField<String, int>>();
      expect(fields.length, 10);
      expect(fields.first.key, longest);
      expect(fields.first.value, longest.length);
      expect(fields.map((f) => f.name), [
        for (var i = 0; i < 10; i++) '$fieldPairPrefix$i',
      ]);
      // The shortest word was pushed out.
      expect(fields.any((f) => f.key == 'аа'), isFalse);
    });
  });

  group('stored statistics', () {
    test('start from scratch when nothing is stored', () {
      final prefs = _Prefs();

      ScoreController.fromPrefs(prefs, GameMode.playerVsAndroid).commit();

      expect(prefs.stored, ScoringSet.initial());
    });

    test('are saved only on commit', () {
      final prefs = _Prefs();
      final controller = ScoreController.fromPrefs(
        prefs,
        GameMode.playerVsAndroid,
      );

      controller.onMoveFinished(_player(), 'москва', 1000, const {});
      expect(prefs.scoringData, isEmpty);

      controller.commit();
      expect(_entries(prefs.stored, groupFrequentCities), {'москва': 1});
    });

    test('continue from the stored values', () {
      final stored = ScoringSet.initial();
      stored[groupParts].main.asIntField().add(5);
      stored[groupParts][fieldAndroid].asIntField().add(4);
      final prefs = _Prefs(scoringData: jsonEncode(stored.toJson()));

      ScoreController.fromPrefs(prefs, GameMode.playerVsAndroid)
        ..onGameFinished(_result(_player()..increaseScore(10)))
        ..commit();

      expect(prefs.stored[groupParts].main.asIntField().value, 6);
      expect(_int(prefs.stored, groupParts, fieldAndroid), 5);
    });

    test('are read back as committed', () {
      final prefs = _Prefs();
      final first = ScoreController.fromPrefs(prefs, GameMode.network);
      final player = _player()..increaseScore(10);
      first
        ..onMoveFinished(player, 'москва', 3000, {ComboType.longWord.index: 1})
        ..onMoveFinished(player, 'анапа', 4000, const {})
        ..onGameFinished(_result(player))
        ..commit();
      final committed = prefs.scoringData;

      ScoreController.fromPrefs(prefs, GameMode.network).commit();

      expect(prefs.scoringData, committed);
      expect(_int(prefs.stored, groupOnline, fieldTime), 7);
      expect(_entries(prefs.stored, groupBigCities), {'москва': 6, 'анапа': 5});
    });

    test('use the scoring type from the preferences', () {
      final player = _player();

      ScoreController.fromPrefs(
        _Prefs(scoringType: ScoringType.lastMove),
        GameMode.playerVsAndroid,
      ).onMoveFinished(player, 'москва', 1000, const {});

      expect(player.score, 0);
    });

    test('without some groups still record a game', () {
      final stored = ScoringSet(
        groups: ScoringSet.initial().groups
            .where(
              (g) =>
                  g.main.name != groupOnline && g.main.name != groupBigCities,
            )
            .toList(),
      );
      final prefs = _Prefs(scoringData: jsonEncode(stored.toJson()));
      final controller = ScoreController.fromPrefs(prefs, GameMode.network);
      final player = _player();

      controller
        ..onMoveFinished(player, 'москва', 5000, const {})
        ..onGameFinished(_result(player))
        ..commit();

      expect(_int(prefs.stored, groupOnline, fieldTime), 5);
      expect(_int(prefs.stored, groupOnline, fieldWins), 1);
      expect(_int(prefs.stored, groupParts, fieldOnline), 1);
      expect(_entries(prefs.stored, groupBigCities), {'москва': 6});
    });

    /// Stored statistics where [change] edited the fields of [group].
    _Prefs prefsWith(
      String group,
      List<ScoringField> Function(List<ScoringField> fields) change,
    ) {
      final stored = ScoringSet.initial();
      stored[group].child = change(stored[group].child);
      return _Prefs(scoringData: jsonEncode(stored.toJson()));
    }

    test('without a field of a group still record the other fields', () {
      final prefs = prefsWith(
        groupOnline,
        (fields) => [
          for (final field in fields)
            if (field.name == fieldWins)
              ScoringField.int(name: fieldWins, value: 3)
            else if (field.name != fieldTime)
              field,
        ],
      );
      final controller = ScoreController.fromPrefs(prefs, GameMode.network);
      final player = _player();

      controller
        ..onMoveFinished(player, 'москва', 5000, const {})
        ..onGameFinished(_result(player))
        ..commit();

      expect(_int(prefs.stored, groupOnline, fieldTime), 5);
      expect(_int(prefs.stored, groupOnline, fieldWins), 4);
      expect(_int(prefs.stored, groupOnline, fieldLose), 0);
    });

    test('keep fields this version does not know in a known group', () {
      final extra = ScoringField.int(name: 'future', value: 7);
      final prefs = prefsWith(groupParts, (fields) => [...fields, extra]);

      ScoreController.fromPrefs(prefs, GameMode.playerVsAndroid).commit();

      expect(prefs.stored[groupParts].findField('future'), extra);
      expect(_int(prefs.stored, groupParts, fieldAndroid), 0);
    });

    test('record combos in the field of their type if the order differs', () {
      final prefs = prefsWith(
        groupCombo,
        (fields) => [
          for (final field in fields.reversed)
            ScoringField.int(name: field.name, value: 1),
        ],
      );

      ScoreController.fromPrefs(prefs, GameMode.playerVsAndroid)
        ..onMoveFinished(_player(), 'москва', 1000, {
          ComboType.quickTime.index: 2,
          ComboType.differentCountries.index: 3,
        })
        ..commit();

      expect(_int(prefs.stored, groupCombo, fieldQuickTime), 2);
      expect(_int(prefs.stored, groupCombo, fieldDiffCountry), 3);
      for (final field in [fieldShortWord, fieldLongWord, fieldSameCountry]) {
        expect(_int(prefs.stored, groupCombo, field), 1, reason: field);
      }
    });

    test('record combos in the field of their type if one is missing', () {
      final prefs = prefsWith(
        groupCombo,
        (fields) => [
          for (final field in fields)
            if (field.name == fieldDiffCountry)
              ScoringField.int(name: fieldDiffCountry, value: 5)
            else if (field.name != fieldSameCountry)
              field,
        ],
      );

      ScoreController.fromPrefs(prefs, GameMode.playerVsAndroid)
        ..onMoveFinished(_player(), 'москва', 1000, {
          ComboType.sameCountry.index: 2,
        })
        ..commit();

      expect(_int(prefs.stored, groupCombo, fieldSameCountry), 2);
      expect(_int(prefs.stored, groupCombo, fieldDiffCountry), 5);
    });

    test('keep groups this version does not know', () {
      final record = ScoringGroup(
        main: ScoringField.empty(name: groupHiscore),
        child: [ScoringField.int(name: fieldAndroid, value: 120)],
      );
      final stored = ScoringSet(
        groups: [...ScoringSet.initial().groups, record],
      );
      final prefs = _Prefs(scoringData: jsonEncode(stored.toJson()));

      ScoreController.fromPrefs(prefs, GameMode.playerVsAndroid).commit();

      expect(prefs.stored[groupHiscore], record);
    });
  });
}
