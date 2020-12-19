import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/stub_account_manager.dart';
import 'package:lets_play_cities/screens/online/logged_in_game_master.dart';

/// Shows Log-in screen if user is not logged in yet or shows
/// [LoggedInOnlineGameMasterScreen].
class OnlineGameMasterScreen extends StatefulWidget {
  /// Creates navigation route to new instance of [OnlineGameMasterScreen]
  static Route createNavigationRoute() =>
      MaterialPageRoute(builder: (_) => OnlineGameMasterScreen());

  final PageStorageBucket bucket = PageStorageBucket();

  @override
  _OnlineGameMasterScreenState createState() => _OnlineGameMasterScreenState();
}

class _OnlineGameMasterScreenState extends State<OnlineGameMasterScreen> {
  http.Client _client;

  @override
  void initState() {
    super.initState();
    _client = http.Client();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<AccountManager>.value(
        value: StubAccountManager(),
        child: Builder(
          builder: (ctx) {
            return ctx.watch<AccountManager>().isSignedIn()
                ? RepositoryProvider<ApiRepository>.value(
                    value: ApiRepository(
                      RemoteLpsApiClient(
                        AppConfig.remotePublicApiURL,
                        _client,
                        ctx
                            .watch<AccountManager>()
                            .getLastSignedInAccount()
                            .credential,
                      ),
                    ),
                    child: LoggedInOnlineGameMasterScreen(),
                  )
                : Container(
                    color: Colors.red,
                    child: Center(child: Text('Unimplemented!')),
                  );
          },
        ),
      );
}
