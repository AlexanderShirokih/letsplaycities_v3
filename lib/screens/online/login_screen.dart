import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/login_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';

/// Shortest name the server accepts, after trimming
const _minNameLength = 2;

/// Sign-in to the online game (`D2-Login`): Google, VK ID or a guest name
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;

  const LoginScreen({super.key, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: GetIt.instance.get<GamePreferences>().lastNativeLogin,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;

    return Scaffold(
      backgroundColor: D2Colors.of(context).bg,
      body: SafeArea(
        child: BlocProvider(
          create: (_) => LoginBloc(
            accountManager: getIt.get<AccountManager>(),
            preferences: getIt.get<GamePreferences>(),
            achievements: getIt.get<AchievementsService>(),
          ),
          child: BlocConsumer<LoginBloc, LoginState>(
            builder: (context, state) => state is LoginAuthenticatingState
                ? LoadingView(context.t.online.authorization)
                : _buildChoices(context),
            listener: (context, state) {
              if (state is LoginAuthCompletedState) {
                widget.onLoggedIn();
              } else if (state is LoginAuthErrorState) {
                _showError(context, context.t.login.socialFailed);
              } else if (state is LoginErrorState) {
                _showError(context, _errorText(context.t, state.error));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChoices(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);

    void signIn(AuthType type) =>
        context.read<LoginBloc>().add(LoginSocialEvent(type));

    return Column(
      children: [
        D2ScreenHeader(onBack: () => Navigator.of(context).maybePop()),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const D2Logo(size: 116),
                              const SizedBox(height: 20),
                              Text(
                                t.online.title,
                                textAlign: TextAlign.center,
                                style: D2Text.display.copyWith(color: c.ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                      D2Button(
                        label: t.login.google,
                        leading: const D2GoogleMark(),
                        kind: D2ButtonKind.outline,
                        size: D2ButtonSize.large,
                        expand: true,
                        onPressed: () => signIn(AuthType.google),
                      ),
                      const SizedBox(height: 16),
                      D2Button(
                        label: t.login.vkId,
                        leading: const D2VkMark(),
                        kind: D2ButtonKind.outline,
                        size: D2ButtonSize.large,
                        expand: true,
                        onPressed: () => signIn(AuthType.vkontakte),
                      ),
                      const SizedBox(height: 16),
                      D2Button(
                        label: t.login.ok,
                        leading: const D2OkMark(),
                        kind: D2ButtonKind.outline,
                        size: D2ButtonSize.large,
                        expand: true,
                        onPressed: () => signIn(AuthType.odnoklassniki),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 28, bottom: 16),
                        child: _GuestDivider(label: t.login.orGuest),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _NameField(
                              controller: _name,
                              hint: t.login.name,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ListenableBuilder(
                            listenable: _name,
                            builder: (context, _) => D2Button(
                              label: t.login.play,
                              size: D2ButtonSize.large,
                              onPressed:
                                  _name.text.trim().length < _minNameLength
                                  ? null
                                  : () => context.read<LoginBloc>().add(
                                      LoginNativeEvent(_name.text.trim()),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showError(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  /// The text of the server if it has one, else the text of the error code
  String _errorText(Translations t, Object error) {
    if (error is! ApiException) return t.login.failed;

    final message = error.message;
    if (message != null && message.isNotEmpty) return message;

    return t.login.errors[error.code] ?? t.login.failed;
  }
}

/// «или играть как гость» between two lines
class _GuestDivider extends StatelessWidget {
  final String label;

  const _GuestDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c.edge)),
        Flexible(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: D2Text.bodyRegular.copyWith(
                fontSize: 14,
                color: c.inkSoft,
              ),
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.edge)),
      ],
    );
  }
}

/// White rounded field that gets a violet ring on focus
class _NameField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;

  const _NameField({required this.controller, required this.hint});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final style = D2Text.body.copyWith(fontSize: 17);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          _focus.hasFocus
              ? BoxShadow(color: c.violet, spreadRadius: 2)
              : BoxShadow(color: c.edge, offset: const Offset(0, 3)),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        autofillHints: const [AutofillHints.nickname],
        textInputAction: TextInputAction.done,
        style: style.copyWith(color: c.ink),
        cursorColor: c.violet,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          hintText: widget.hint,
          hintStyle: style.copyWith(color: c.inkSoft),
        ),
      ),
    );
  }
}
