import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/achievements/local_achievements.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/online/avatars/avatar_chooser.dart';
import 'package:lets_play_cities/screens/online/banlist.dart';
import 'package:lets_play_cities/screens/online/friends.dart';
import 'package:lets_play_cities/screens/online/game_master.dart';
import 'package:lets_play_cities/screens/online/history.dart';
import 'package:lets_play_cities/screens/profile/achievements_row.dart';
import 'package:lets_play_cities/screens/profile/passport_card.dart';
import 'package:lets_play_cities/screens/root/root_screen.dart';
import 'package:lets_play_cities/screens/settings/settings_screen.dart';

/// Position of the profile among the root tabs
const profileTabIndex = 2;

/// What the profile shows about the local player, read from the device
class _LocalProfile {
  final List<int> countries;
  final int games;
  final int onlineWins;
  final int onlineGames;

  const _LocalProfile({
    required this.countries,
    required this.games,
    required this.onlineWins,
    required this.onlineGames,
  });

  factory _LocalProfile.read(GamePreferences prefs) {
    final data = prefs.scoringData;
    final set = data.isEmpty
        ? ScoringSet.initial()
        : ScoringSet.fromJson(jsonDecode(data));
    final online = set[groupOnline];
    final wins = online[fieldWins].asIntField().value ?? 0;
    final lose = online[fieldLose].asIntField().value ?? 0;

    final ranked =
        set[groupCountries].child
            .whereType<PairedScoringField<String, int>>()
            .where((field) => int.tryParse(field.key ?? '') != null)
            .toList()
          ..sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));

    return _LocalProfile(
      countries: [for (final field in ranked) int.parse(field.key!)],
      games: set[groupParts].main.asIntField().value ?? 0,
      onlineWins: wins,
      onlineGames: wins + lose,
    );
  }
}

/// The signed-in online account with its repository
class _OnlineProfile {
  final RemoteAccount account;
  final ApiRepository repository;
  final BaseProfileInfo info;

  const _OnlineProfile(this.account, this.repository, this.info);
}

/// «Профиль» tab: the player, the passport of countries, metrics,
/// achievements and the links to online screens and settings
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  ValueListenable<int>? _visibleTab;
  Future<Map<int, String>>? _names;
  _LocalProfile? _local;
  _OnlineProfile? _online;

  /// `true` until the account is known
  bool _loading = true;

  /// Tells a stale account load from the current one
  int _loads = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final listenable = RootScreen.maybeOf(context)?.selectedIndex;
    if (listenable != _visibleTab) {
      _visibleTab?.removeListener(_onTabChanged);
      _visibleTab = listenable?..addListener(_onTabChanged);
    }

    _names ??= _loadNames();
    // The achievements and statistics do not notify, so they are read again
    // each time the tab is shown.
    _local = _LocalProfile.read(context.read<GamePreferences>());
    if (_loads == 0) _loadAccount();
  }

  @override
  void dispose() {
    _visibleTab?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (_visibleTab?.value != profileTabIndex) return;

    setState(() {
      _local = _LocalProfile.read(context.read<GamePreferences>());
    });
    _loadAccount();
  }

  Future<Map<int, String>> _loadNames() async {
    try {
      final list = await GetIt.instance
          .get<CountryRepository>()
          .getCountryList();

      return {for (final c in list) c.countryCode: c.name};
    } catch (_) {
      return const {};
    }
  }

  /// Fetches the account and its profile. Without the account, or without the
  /// network, the header stays local.
  Future<void> _loadAccount({bool refresh = false}) async {
    final load = ++_loads;
    final getIt = GetIt.instance;
    _OnlineProfile? online;

    try {
      final account = await getIt
          .get<AccountManager>()
          .getLastSignedInAccount();
      if (account != null) {
        final repository = getIt.get<ApiRepositoryFactory>().forCredential(
          account.credential,
        );
        var info = account.baseProfileInfo;
        try {
          info = await repository.getProfileInfo(info, refresh);
        } catch (_) {
          // Offline: the account holds the name and the picture too.
        }
        online = _OnlineProfile(account, repository, info);
      }
    } catch (_) {
      online = null;
    }

    if (!mounted || load != _loads) return;

    setState(() {
      _online = online;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final local = _local!;
    final achievements = GetIt.instance.get<LocalAchievementsService>();
    final service = GetIt.instance.get<AchievementsService>();

    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.profile.title,
                    style: D2Text.display.copyWith(fontSize: 22, color: c.ink),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _Header(
                online: _online,
                loading: _loading,
                onAvatar: _online == null ? null : _chooseAvatar,
                onSignIn: _signIn,
              ),
              const SizedBox(height: 8),
              FutureBuilder<Map<int, String>>(
                future: _names,
                builder: (context, names) => PassportCard(
                  countries: local.countries,
                  names: names.data ?? const {},
                ),
              ),
              const SizedBox(height: 8),
              _Metrics(local: local),
              const SizedBox(height: 8),
              AchievementsRow(
                isUnlocked: achievements.isUnlocked,
                onRating: service.showLeaderboardScreen,
                onAll: service.showAchievementsScreen,
              ),
              const SizedBox(height: 8),
              D2Card(padding: EdgeInsets.zero, child: _rows(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rows(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final online = _online;
    final rows = [
      if (online != null) ...[
        _NavigationRow(
          glyph: D2Glyph.friends,
          label: t.profile.friends,
          onTap: () =>
              _openOnline(t.profile.friends, const OnlineFriendsScreen()),
        ),
        _NavigationRow(
          glyph: D2Glyph.history,
          label: t.profile.history,
          onTap: () => _openOnline(
            t.profile.history,
            OnlineHistoryScreen(target: online.info),
          ),
        ),
        _NavigationRow(
          glyph: D2Glyph.ban,
          label: t.profile.blacklist,
          onTap: () =>
              _openOnline(t.profile.blacklist, const OnlineBanlistScreen()),
        ),
      ],
      _NavigationRow(
        glyph: D2Glyph.settings,
        label: t.profile.settings,
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => SettingsScreen())),
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Container(height: 2, color: c.bg),
          rows[i],
        ],
      ],
    );
  }

  Future<void> _signIn() async {
    await Navigator.of(context)
        .push(OnlineGameMasterScreen.createNavigationRoute());

    if (mounted) _loadAccount();
  }

  void _chooseAvatar() {
    final online = _online;
    if (online == null) return;

    showD2Sheet<void>(
      context,
      builder: (_) => AvatarChooserView(
        online.repository,
        onAvatarUpdated: () => _loadAccount(refresh: true),
      ),
    );
  }

  Future<void> _openOnline(String title, Widget screen) {
    final online = _online!;

    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ApiRepository>.value(value: online.repository),
            RepositoryProvider<AccountManager>.value(
              value: GetIt.instance.get<AccountManager>(),
            ),
          ],
          child: Scaffold(
            appBar: AppBar(title: Text(title)),
            body: screen,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final _OnlineProfile? online;
  final bool loading;
  final VoidCallback? onAvatar;
  final VoidCallback onSignIn;

  const _Header({
    required this.online,
    required this.loading,
    required this.onAvatar,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final info = online?.info;
    final name = info?.login ?? t.players.player;

    Widget avatar = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.yellow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.22),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: D2Avatar.user(
        size: 72,
        pictureUrl: info?.pictureUrl,
        initials: name.isEmpty ? '' : name.substring(0, 1).toUpperCase(),
      ),
    );
    avatar = Transform.rotate(angle: -3 * 3.14159265 / 180, child: avatar);
    if (onAvatar != null) {
      avatar = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onAvatar,
        child: avatar,
      );
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: D2Text.title.copyWith(fontSize: 20, color: c.ink),
              ),
              if (online != null) ...[
                const SizedBox(height: 5),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'ID ${online!.account.credential.userId}',
                      style: D2Text.caption.copyWith(color: c.inkSoft),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: c.mint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.profile.online,
                          style: D2Text.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: c.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else if (!loading) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: D2Button(
                    label: t.profile.signIn,
                    kind: D2ButtonKind.accent,
                    onPressed: onSignIn,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Metrics extends StatelessWidget {
  final _LocalProfile local;

  const _Metrics({required this.local});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: Wrap(
        spacing: 18,
        runSpacing: 4,
        children: [
          _Metric('${local.games}', t.profile.games),
          _Metric(
            '${local.onlineWins}',
            t.profile.onlineWinsOf(count: local.onlineGames),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: D2Text.section.copyWith(fontSize: 17, color: c.ink)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: D2Text.caption.copyWith(color: c.inkSoft)),
        ),
      ],
    );
  }
}

class _NavigationRow extends StatelessWidget {
  final D2Glyph glyph;
  final String label;
  final VoidCallback onTap;

  const _NavigationRow({
    required this.glyph,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: D2Icon(glyph, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: D2Text.body.copyWith(color: c.ink)),
                ),
                RotatedBox(
                  quarterTurns: 2,
                  child: D2Icon(D2Glyph.back, size: 18, color: c.inkSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
