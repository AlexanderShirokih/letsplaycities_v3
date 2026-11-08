import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/login_screen.dart';

/// Checks current authentication state. Without a session it first signs in
/// the account of this device silently, and runs [LoginScreen] if there is
/// none. Runs [onLoggedIn] when user signed in.
/// Authenticated [RemoteAccount] will be injected via [RepositoryProvider].
class AuthenticationView extends StatefulWidget {
  final WidgetBuilder onLoggedIn;

  const AuthenticationView({super.key, required this.onLoggedIn});

  @override
  State<AuthenticationView> createState() => _AuthenticationViewState();
}

class _AuthenticationViewState extends State<AuthenticationView> {
  final _accountManager = GetIt.instance.get<AccountManager>();

  // Kept between builds: each new future may sign in again.
  late Future<RemoteAccount?> _account = _signIn();

  Future<RemoteAccount?> _signIn() async =>
      await _accountManager.getLastSignedInAccount() ??
      await _accountManager.trySilentNative();

  void _reload() => setState(() {
    _account = _signIn();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<RemoteAccount?>(
    future: _account,
    builder: (context, account) {
      if (account.connectionState != ConnectionState.done) {
        return LoadingView(context.t.online.fetchingProfile);
      }

      if (account.hasError) {
        final error = account.error;

        return ConnectionErrorView(
          onReload: _reload,
          errorMessage: switch (error) {
            AuthorizationException() => authorizationErrorText(
              context.t,
              error,
            ),
            // E.g. `banned`: the text of the server
            ApiException(:final message?) => message,
            _ => null,
          },
        );
      }

      final signedIn = account.data;
      if (signedIn == null) {
        return LoginScreen(onLoggedIn: _reload);
      }

      return RepositoryProvider<RemoteAccount>.value(
        value: signedIn,
        child: widget.onLoggedIn(context),
      );
    },
  );
}
