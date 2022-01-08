import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/login_bloc.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  final GamePreferences preferences;
  final VoidCallback onLoggedIn;

  const LoginScreen({
    Key? key,
    required this.onLoggedIn,
    required this.preferences,
  }) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _loginController;
  bool _hasLogin = false;

  @override
  void initState() {
    super.initState();
    _loginController =
        TextEditingController(text: widget.preferences.lastNativeLogin);
    _hasLogin = _loginController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _loginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorLight,
        shadowColor: Colors.transparent,
      ),
      body: BlocProvider(
        create: (context) => LoginBloc(
          NativeBridgeSocialNetworksService(),
        ),
        child: BlocConsumer<LoginBloc, LoginState>(
          builder: (context, state) {
            if (state is LoginAuthenticatingState) {
              return LoadingView('Авторизация...');
            } else if (state is LoginAuthUpdateAvatarState) {
              return LoadingView('Обновление картинки профиля');
            }
            return _buildLoginView(context);
          },
          listener: (context, state) {
            if (state is LoginAuthCompletedState) {
              widget.onLoggedIn();
            } else if (state is LoginAuthErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Не удалось войти через соц.сеть')),
              );
            } else if (state is LoginErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Что-то пошло не так :(. Попробуте снова')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoginView(BuildContext context) => Container(
        color: Theme.of(context).primaryColorLight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Вход',
                style: Theme.of(context).textTheme.headline4!.copyWith(
                    color: Theme.of(context).accentColor,
                    fontWeight: FontWeight.w600),
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
                          labelText: 'Ваше имя',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                      ),
                      const SizedBox(height: 18.0),
                      Text(
                          'Используйте вход через социальные сети чтобы не потерять свой аккаунт'),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 18, 18, 0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Theme.of(context).primaryColor,
                            elevation: 6.0,
                          ),
                          onPressed: _hasLogin
                              ? () => context
                                  .read<LoginBloc>()
                                  .add(LoginNativeEvent(_loginController.text))
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text('Войти'),
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
                  'или войти используя',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.all(14.0),
                    color: Colors.red,
                    icon: FaIcon(FontAwesomeIcons.google),
                    onPressed: () => _runSocialSignUp(context, AuthType.Google),
                  ),
                  IconButton(
                    padding: EdgeInsets.all(14.0),
                    color: Colors.blueAccent,
                    icon: FaIcon(FontAwesomeIcons.vk),
                    onPressed: () =>
                        _runSocialSignUp(context, AuthType.Vkontakte),
                  ),
                  IconButton(
                    padding: EdgeInsets.all(14.0),
                    color: Colors.orange,
                    icon: FaIcon(FontAwesomeIcons.odnoklassniki),
                    onPressed: () =>
                        _runSocialSignUp(context, AuthType.Odnoklassniki),
                  ),
                  IconButton(
                    padding: EdgeInsets.all(14.0),
                    color: Colors.indigo,
                    icon: FaIcon(FontAwesomeIcons.facebook),
                    onPressed: () =>
                        _runSocialSignUp(context, AuthType.Facebook),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _runSocialSignUp(BuildContext context, AuthType authType) {
    context.read<LoginBloc>().add(LoginSocialEvent(authType));
  }
}
