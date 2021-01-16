import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/login_screen.dart';

/// Checks current authentication state. Runs [LoginScreen] if user
/// is not signed in. Runs [onLoggedIn] when user signed in.
/// Authenticated [RemoteAccount] will be injected via [RepositoryProvider].
class AuthenticationView extends StatefulWidget {
  final WidgetBuilder onLoggedIn;

  const AuthenticationView({Key? key, required this.onLoggedIn})
      : super(key: key);

  @override
  _AuthenticationViewState createState() => _AuthenticationViewState();
}

class _AuthenticationViewState extends State<AuthenticationView> {
  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<AccountManager>.value(
        value: AccountManager.fromPreferences(context.watch<GamePreferences>()),
        child: Builder(
          builder: (ctx) {
            return FutureBuilder<RemoteAccount?>(
              future: ctx.watch<AccountManager>().getLastSignedInAccount(),
              builder: (context, lastSignedInAccount) {
                if (lastSignedInAccount.hasError) {
                  return ConnectionErrorView(onReload: () => setState(() {}));
                }
                if (!lastSignedInAccount.hasData) {
                  if (lastSignedInAccount.connectionState ==
                      ConnectionState.done) {
                    return LoginScreen(
                      onLoggedIn: () => setState(() {}),
                      preferences: context.watch<GamePreferences>(),
                    );
                  } else {
                    return buildWithLocalization(context,
                        (l10n) => LoadingView(l10n.online['fetching_profile']));
                  }
                }
                return RepositoryProvider<RemoteAccount>.value(
                  value: lastSignedInAccount.requireData!,
                  child: widget.onLoggedIn(context),
                );
              },
            );
          },
        ),
      );
}
