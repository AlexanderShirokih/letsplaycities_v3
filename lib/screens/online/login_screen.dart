import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/login_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  final GamePreferences preferences;
  final VoidCallback onLoggedIn;

  const LoginScreen({
    super.key,
    required this.onLoggedIn,
    required this.preferences,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _loginController;
  bool _hasLogin = false;

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController(
      text: widget.preferences.lastNativeLogin,
    );
    _hasLogin = _loginController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _loginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorLight,
        shadowColor: Colors.transparent,
      ),
      body: BlocProvider(
        create: (context) => LoginBloc(
          socialNetworksService: NativeBridgeSocialNetworksService(),
          accountManager: GetIt.instance.get<AccountManager>(),
          preferences: GetIt.instance.get<GamePreferences>(),
          cloudServices: GetIt.instance.get<CloudMessagingService>(),
          apiRepositories: () => GetIt.instance.get<ApiRepositoryFactory>(),
        ),
        child: BlocConsumer<LoginBloc, LoginState>(
          builder: (context, state) {
            if (state is LoginAuthenticatingState) {
              return LoadingView(t.online.authorization);
            } else if (state is LoginAuthUpdateAvatarState) {
              return LoadingView(t.login.updatingAvatar);
            }
            return _buildLoginView(context);
          },
          listener: (context, state) {
            if (state is LoginAuthCompletedState) {
              widget.onLoggedIn();
            } else if (state is LoginAuthErrorState) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(t.login.socialFailed)));
            } else if (state is LoginErrorState) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(t.login.failed)));
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoginView(BuildContext context) {
    final t = context.t;
    return Container(
      color: Theme.of(context).primaryColorLight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              t.login.title,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.0),
            Card(
              margin: const EdgeInsets.all(32.0),
              elevation: 6.0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _loginController,
                      onChanged: (text) => setState(() {
                        _hasLogin = text.isNotEmpty;
                      }),
                      decoration: InputDecoration(
                        labelText: t.login.nameLabel,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_circle_outlined),
                      ),
                    ),
                    const SizedBox(height: 18.0),
                    Text(t.login.socialHint),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 18, 18, 0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          elevation: 6.0,
                        ),
                        onPressed: _hasLogin
                            ? () => context.read<LoginBloc>().add(
                                LoginNativeEvent(_loginController.text),
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(t.login.signIn),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 18.0),
              child: Text(
                t.login.orSignInWith,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.all(14.0),
                  color: Colors.red,
                  icon: FaIcon(FontAwesomeIcons.google),
                  onPressed: () => _runSocialSignUp(context, AuthType.google),
                ),
                IconButton(
                  padding: EdgeInsets.all(14.0),
                  color: Colors.blueAccent,
                  icon: FaIcon(FontAwesomeIcons.vk),
                  onPressed: () =>
                      _runSocialSignUp(context, AuthType.vkontakte),
                ),
                IconButton(
                  padding: EdgeInsets.all(14.0),
                  color: Colors.orange,
                  icon: FaIcon(FontAwesomeIcons.odnoklassniki),
                  onPressed: () =>
                      _runSocialSignUp(context, AuthType.odnoklassniki),
                ),
                IconButton(
                  padding: EdgeInsets.all(14.0),
                  color: Colors.indigo,
                  icon: FaIcon(FontAwesomeIcons.facebook),
                  onPressed: () => _runSocialSignUp(context, AuthType.facebook),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _runSocialSignUp(BuildContext context, AuthType authType) {
    context.read<LoginBloc>().add(LoginSocialEvent(authType));
  }
}
