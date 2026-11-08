import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/login_screen.dart';

/// Checks current authentication state. Runs [LoginScreen] if user
/// is not signed in. Runs [onLoggedIn] when user signed in.
/// Authenticated [RemoteAccount] will be injected via [RepositoryProvider].
class AuthenticationView extends StatefulWidget {
  final WidgetBuilder onLoggedIn;

  const AuthenticationView({super.key, required this.onLoggedIn});

  @override
  State<AuthenticationView> createState() => _AuthenticationViewState();
}

class _AuthenticationViewState extends State<AuthenticationView> {
  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<AccountManager>.value(
        value: GetIt.instance.get<AccountManager>(),
        child: Builder(
          builder: (ctx) {
            return FutureBuilder<RemoteAccount?>(
              future: ctx.watch<AccountManager>().getLastSignedInAccount(),
              builder: (context, lastSignedInAccount) {
                if (lastSignedInAccount.hasError) {
                  final error = lastSignedInAccount.error;
                  if (error is AuthorizationException) {
                    return ConnectionErrorView(
                      onReload: () => setState(() {}),
                      errorMessage: authorizationErrorText(context.t, error),
                    );
                  } else {
                    return ConnectionErrorView(onReload: () => setState(() {}));
                  }
                }
                if (!lastSignedInAccount.hasData) {
                  if (lastSignedInAccount.connectionState ==
                      ConnectionState.done) {
                    return LoginScreen(
                      onLoggedIn: () => setState(() {}),
                      preferences: context.watch<GamePreferences>(),
                    );
                  } else {
                    return LoadingView(context.t.online.fetchingProfile);
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
