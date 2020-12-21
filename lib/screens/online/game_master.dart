import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/remote_module.dart';
import 'package:lets_play_cities/remote/stub_account_manager.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/online/logged_in_game_master.dart';

/// Shows Log-in screen if user is not logged in yet or shows
/// [LoggedInOnlineGameMasterScreen].
class OnlineGameMasterScreen extends StatelessWidget {
  /// Creates navigation route to new instance of [OnlineGameMasterScreen]
  static Route createNavigationRoute() =>
      MaterialPageRoute(builder: (_) => OnlineGameMasterScreen());

  final PageStorageBucket bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<AccountManager>.value(
        value: StubAccountManager(),
        child: Builder(
          builder: (ctx) {
            return ctx.watch<AccountManager>().isSignedIn()
                ? FutureBuilder<RemoteAccountInfo>(
                    future:
                        ctx.watch<AccountManager>().getLastSignedInAccount(),
                    builder: (context, lastSignedInAccount) {
                      if (!lastSignedInAccount.hasData) {
                        return LoadingView('...');
                      }
                      return RepositoryProvider<ApiRepository>.value(
                        value: ApiRepository(
                          RemoteLpsApiClient(
                            getDio(),
                            lastSignedInAccount.requireData.credential,
                          ),
                        ),
                        child: LoggedInOnlineGameMasterScreen(),
                      );
                    },
                  )
                : Container(
                    color: Colors.red,
                    child: Center(child: Text('Unimplemented!')),
                  );
          },
        ),
      );
}
