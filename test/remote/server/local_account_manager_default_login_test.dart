import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/server/local_account_manager.dart';

/// The main server has no signed-in account.
class _SignedOutAccountManager extends Fake implements AccountManager {
  @override
  Future<RemoteAccount?> getLastSignedInAccount() async => null;
}

/// The user has never entered a login for a native account.
class _NoSavedLoginPreferences extends Fake implements GamePreferences {
  @override
  String get lastNativeLogin => '';

  @override
  bool get onlineChatEnabled => false;
}

/// Signs every request up and remembers what it was sent.
class _RecordingSignUp
    implements SingleAsyncUseCase<RemoteSignUpData, RemoteSignUpResponse> {
  final sent = <RemoteSignUpData>[];

  @override
  Future<RemoteSignUpResponse> execute(RemoteSignUpData request) async {
    sent.add(request);
    return RemoteSignUpResponse(
      accessToken: 'local_token',
      login: request.login,
      authType: AuthType.native,
      role: Role.regular,
      userId: 77,
      pictureHash: '',
    );
  }
}

void main() {
  test(
    'a native account without a saved login takes the default login',
    () async {
      final signUp = _RecordingSignUp();
      final accountManager = LocalAccountManager(
        _SignedOutAccountManager(),
        _NoSavedLoginPreferences(),
        signUp,
        'default_login',
      );

      final account = await accountManager.getLastSignedInAccount();

      expect(signUp.sent.single.login, 'default_login');
      expect(account!.name, 'default_login');
    },
  );
}
