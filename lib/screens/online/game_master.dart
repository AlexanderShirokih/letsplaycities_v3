import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/account_manager_impl.dart';
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
        value: AccountManagerImpl(),
        child: Builder(
          builder: (ctx) {
            final accountManager = ctx.watch<AccountManager>();
            return accountManager.isSignedIn()
                ? FutureBuilder<RemoteAccount>(
                    future:
                        ctx.watch<AccountManager>().getLastSignedInAccount(),
                    builder: (context, lastSignedInAccount) {
                      if (!lastSignedInAccount.hasData) {
                        return LoadingView('...');
                      }
                      return RepositoryProvider<RemoteAccount>.value(
                        value: lastSignedInAccount.requireData,
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
