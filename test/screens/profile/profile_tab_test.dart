import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/achievements/local_achievements.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/profile/profile_tab.dart';
import 'package:lets_play_cities/screens/root/root_screen.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import '../online/online_fakes.dart';
import '../../i18n/translations_harness.dart';

class _Prefs extends Fake implements GamePreferences {
  @override
  String scoringData;

  @override
  Map<String, int> achievementsProgress;

  _Prefs(this.scoringData, [this.achievementsProgress = const {}]);
}

class _Countries extends Fake implements CountryRepository {
  @override
  Future<List<CountryEntity>> getCountryList() async => [
    for (var i = 0; i < 30; i++) CountryEntity('Страна $i', i + 1, false),
  ];
}

class _Factory extends Fake implements ApiRepositoryFactory {
  final ApiRepository repository;

  _Factory(this.repository);

  @override
  ApiRepository forUser() => repository;
}

String _scoring({
  int countries = 0,
  int parts = 0,
  int wins = 0,
  int lose = 0,
}) {
  final set = ScoringSet.initial();
  set[groupCountries].child = [
    for (var i = 0; i < countries; i++)
      PairedScoringField<String, int>('pval$i', '${i + 1}', countries - i),
  ];
  set[groupParts].main.asIntField().value = parts;
  set[groupOnline][fieldWins].asIntField().value = wins;
  set[groupOnline][fieldLose].asIntField().value = lose;

  return jsonEncode(set.toJson());
}

void main() {
  final t = AppLocale.ru.buildSync();

  late FakeApiRepository repository;
  late _Prefs fakePrefs;
  late FakeAccountManager accounts;

  void register({
    RemoteAccount? account,
    String? scoring,
    Map<String, int> progress = const {},
  }) {
    final prefs = _Prefs(scoring ?? _scoring(), progress);
    repository = FakeApiRepository()..profiles = {2: userProfile(2, 'Alice')};
    final getIt = GetIt.instance;
    accounts = FakeAccountManager(account);
    getIt.registerSingleton<AccountManager>(accounts);
    getIt.registerSingleton<GamePreferences>(prefs);
    getIt.registerSingleton<ApiRepositoryFactory>(_Factory(repository));
    getIt.registerSingleton<CountryRepository>(_Countries());
    final local = LocalAchievementsService(
      FakeAchievementsService(),
      prefs,
      SimpleErrorLogger(),
    );
    getIt.registerSingleton<LocalAchievementsService>(local);
    getIt.registerSingleton<AchievementsService>(local);
    addTearDown(getIt.reset);

    fakePrefs = prefs;
  }

  Future<void> pump(WidgetTester tester, {bool narrow = false}) async {
    if (narrow) {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildD2Theme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(narrow ? 1.3 : 1)),
            child: child!,
          ),
          home: const Scaffold(body: ProfileTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('profile tab without account shows local profile', (
    tester,
  ) async {
    register();
    await pump(tester);

    expect(find.text(t.profile.signIn), findsOneWidget);
    expect(find.text(t.profile.passport), findsOneWidget);
    expect(find.text(t.profile.friends), findsNothing);
    expect(find.text(t.profile.settings), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile tab with account shows id and online rows', (
    tester,
  ) async {
    register(account: remoteAccount(2, 'Alice'));
    await pump(tester);

    expect(find.text('ID 2'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text(t.profile.online), findsOneWidget);
    expect(find.text(t.profile.friends), findsOneWidget);
    expect(find.text(t.profile.history), findsOneWidget);
    expect(find.text(t.profile.blacklist), findsOneWidget);
    expect(find.text(t.profile.signIn), findsNothing);
  });

  testWidgets('sign-out is in the header only when signed in', (tester) async {
    register(account: remoteAccount(2, 'Alice'));
    await pump(tester);

    await tester.tap(find.text(t.online.signOut));
    await tester.pumpAndSettle();

    expect(accounts.signOuts, 1);
    expect(find.text('ID 2'), findsNothing);
    expect(find.text(t.profile.signIn), findsOneWidget);
    expect(find.text(t.online.signOut), findsNothing);
  });

  testWidgets('a failed online profile falls back to the account', (
    tester,
  ) async {
    register(account: remoteAccount(7, 'Bob'));
    await pump(tester);

    expect(find.text('ID 7'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('passport shows count and overflow tile', (tester) async {
    register(scoring: _scoring(countries: 23));
    await pump(tester);

    expect(find.text(t.profile.countriesCount(count: 23)), findsOneWidget);
    expect(find.text('23 страны'), findsOneWidget);
    expect(find.text('+12'), findsOneWidget);
  });

  testWidgets('passport lists all countries without counts', (tester) async {
    register(scoring: _scoring(countries: 13));
    await pump(tester);

    await tester.tap(find.text(t.profile.all).first);
    await tester.pumpAndSettle();

    expect(find.text('Страна 0'), findsWidgets);
    expect(find.text('Страна 12'), findsOneWidget);
  });

  testWidgets('metrics show games and online wins', (tester) async {
    register(scoring: _scoring(parts: 128, wins: 17, lose: 11));
    await pump(tester);

    expect(find.text('128'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(find.text('побед онлайн из 28'), findsOneWidget);
  });

  testWidgets('locked achievement has semantics hint', (tester) async {
    register(progress: {Achievement.use3Tips.wireName: 3});
    await pump(tester);

    final locked = Achievement.write15Cities.label(t);
    expect(
      find.bySemanticsLabel(t.profile.achievementLocked(title: locked)),
      findsOneWidget,
    );
    final unlocked = Achievement.use3Tips.label(t);
    expect(find.bySemanticsLabel(unlocked), findsOneWidget);
  });

  testWidgets('profile fits a narrow screen with large text', (tester) async {
    register(
      account: remoteAccount(2, 'Alice'),
      scoring: _scoring(countries: 23, parts: 128, wins: 17, lose: 11),
    );
    await pump(tester, narrow: true);

    expect(tester.takeException(), isNull);
  });

  testWidgets('profile reads achievements again when the tab is shown', (
    tester,
  ) async {
    register();
    await tester.pumpWidget(
      RepositoryProvider<GamePreferences>.value(
        value: fakePrefs,
        child: withTranslations(
          MaterialApp(
            theme: buildD2Theme(Brightness.light),
            home: Scaffold(
              body: RootScreen(
                initialTab: profileTabIndex,
                tabsOverride: [
                  (_) => const SizedBox(),
                  (_) => const SizedBox(),
                  (_) => const ProfileTab(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = Achievement.use3Tips.label(t);
    final locked = find.bySemanticsLabel(
      t.profile.achievementLocked(title: title),
    );
    expect(locked, findsOneWidget);

    fakePrefs.achievementsProgress = {Achievement.use3Tips.wireName: 3};
    final nav = find.byType(D2BottomNav);
    await tester.tap(
      find.descendant(of: nav, matching: find.text(t.home.play)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: nav, matching: find.text(t.home.profile)),
    );
    await tester.pumpAndSettle();

    expect(locked, findsNothing);
    expect(find.bySemanticsLabel(title), findsOneWidget);
  });

  testWidgets('profile shows the new account after an avatar change', (
    tester,
  ) async {
    register(account: remoteAccount(2, 'Alice'));
    await pump(tester);
    expect(find.text('Alice'), findsOneWidget);

    accounts.account = remoteAccount(2, 'Alice B');
    accounts.invalidate();
    await tester.pumpAndSettle();

    expect(find.text('Alice B'), findsOneWidget);
    expect(accounts.fetches, 2);
  });
}
