import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/logged_in_game_master.dart';
import 'package:lets_play_cities/screens/online/login_screen.dart';

/// Shows Log-in screen if user is not logged in yet or shows
/// [LoggedInOnlineGameMasterScreen].
class OnlineGameMasterScreen extends StatefulWidget {
  /// Creates navigation route to new instance of [OnlineGameMasterScreen]
  static Route createNavigationRoute() =>
      MaterialPageRoute(builder: (_) => OnlineGameMasterScreen());

  @override
  _OnlineGameMasterScreenState createState() => _OnlineGameMasterScreenState();
}

class _OnlineGameMasterScreenState extends State<OnlineGameMasterScreen> {
  final PageStorageBucket bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<AccountManager>.value(
        value: AccountManager.fromPreferences(context.watch<GamePreferences>()),
        child: Builder(
          builder: (ctx) {
            return FutureBuilder<RemoteAccount>(
              future: ctx.watch<AccountManager>().getLastSignedInAccount(),
              builder: (context, lastSignedInAccount) {
                if (lastSignedInAccount.hasError) {
                  return ConnectionErrorView(onReload: () => setState(() {}));
                }
                if (!lastSignedInAccount.hasData) {
                  if (lastSignedInAccount.connectionState ==
                      ConnectionState.done) {
                    return LoginScreen();
                  } else {
                    return buildWithLocalization(context,
                        (l10n) => LoadingView(l10n.online['fetching_profile']));
                  }
                }
                return RepositoryProvider<RemoteAccount>.value(
                  value: lastSignedInAccount.requireData,
                  child: LoggedInOnlineGameMasterScreen(),
                );
              },
            );
          },
        ),
      );
}
