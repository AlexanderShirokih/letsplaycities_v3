import 'dart:async';

import 'package:dio/dio.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/auth_api.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Account on the main server, signed in by the token in
/// [ApiRepositoryFactory.tokens].
class AccountManagerImpl implements AccountManager {
  /// How long the account from `GET /v1/me` is served without a new request
  static const accountLifetime = Duration(minutes: 5);

  final GamePreferences _preferences;
  final ApiRepositoryFactory _apiRepositories;
  final AuthApi _auth;
  final SocialNetworksService _socialNetworks;
  final CloudMessagingService _messaging;
  final ErrorLogger _logger;
  final DateTime Function() _clock;

  /// Runs after a sign-out, e.g. to close the game connection
  final Future<void> Function()? _onSignedOut;

  AccountManagerImpl({
    required this._preferences,
    required this._apiRepositories,
    required this._auth,
    required this._socialNetworks,
    required this._messaging,
    required this._logger,
    DateTime Function()? clock,
    this._onSignedOut,
  }) : _clock = clock ?? DateTime.now;

  RemoteAccount? _account;
  DateTime? _accountTime;

  /// The token that [_account] was signed in with
  String? _accountToken;
  Future<RemoteAccount?>? _accountRequest;

  /// Changes on every sign-in and sign-out, so the answer to a request of an
  /// older session is not kept.
  int _session = 0;

  /// Changes on every sign-in and sign-out only, unlike [_session], which
  /// [invalidate] changes too. Work that belongs to one signed-in account
  /// (the FCM token, the picture) is dropped when this changes.
  int _signIn = 0;

  final _changes = StreamController<void>.broadcast();

  /// Sends the refreshed FCM tokens while a session is known
  StreamSubscription<String>? _fcmRefreshes;

  @override
  Stream<void> get accountChanges => _changes.stream;

  @override
  void invalidate() {
    // An answer to a request that was sent before is not kept
    _session++;
    _forgetAccount();
    _accountRequest = null;
    _changes.add(null);
  }

  @override
  Future<RemoteAccount?> getLastSignedInAccount() async {
    // Any request that gets a 401 drops the token, so the token decides.
    final token = await _apiRepositories.tokens.read();
    if (token == null || token.isEmpty) {
      _forgetAccount();
      return null;
    }

    final account = _account;
    final time = _accountTime;
    if (account != null &&
        time != null &&
        token == _accountToken &&
        _clock().difference(time) < accountLifetime) {
      return account;
    }

    return _accountRequest ??= _fetchAccount(token)
        .whenComplete(() => _accountRequest = null);
  }

  Future<RemoteAccount?> _fetchAccount(String token) async {
    final session = _session;
    try {
      final account = _toAccount(await _auth.me());
      if (session == _session) {
        _keepAccount(account, token);
        if (_fcmRefreshes == null) unawaited(_startFcmSync(_signIn));
      }

      return account;
    } on UnauthorizedException {
      // The interceptor has dropped the token.
      if (session == _session) _forgetAccount();
      return null;
    }
  }

  @override
  Future<RemoteAccount?> trySilentNative() async {
    // After a sign-out the user chooses the account on the login screen:
    // the server would sign the device account straight back in.
    if (_preferences.signedOut) return null;

    try {
      final deviceId = await _socialNetworks.getDeviceId();

      return await _startSession(await _auth.native(deviceId, ''));
    } on ApiException {
      // `bad_name`: the device has no account and the user has to name it.
      // The others (`banned`, `too_many_requests`) the login screen shows
      // when the user signs in.
      return null;
    } on DioException {
      return null;
    } catch (e, s) {
      _logger.error(e, s);
      return null;
    }
  }

  @override
  Future<RemoteAccount> signInNative(String name) async {
    final deviceId = await _socialNetworks.getDeviceId();

    return _startSession(await _auth.native(deviceId, name.trim()));
  }

  @override
  Future<RemoteAccount> signInSocial(AuthType type) async {
    final network = await _socialNetworks.login(type);
    final result = await _auth.social(
      type.provider,
      network.accessToken,
      network.login,
    );
    final account = await _startSession(result);

    if (result.user.avatarHash == null && network.pictureUri.isNotEmpty) {
      unawaited(_uploadPicture(network.pictureUri, _signIn));
    }

    return account;
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.logout();
    } catch (_) {
      // The token is dropped anyway; the server forgets it in time.
    }

    _session++;
    _signIn++;
    _preferences.signedOut = true;
    _forgetAccount();
    await _fcmRefreshes?.cancel();
    _fcmRefreshes = null;
    await _apiRepositories.tokens.clear();
    _apiRepositories.cache.clear();
    try {
      await _onSignedOut?.call();
    } catch (e, s) {
      _logger.error(e, s);
    }
    _changes.add(null);
  }

  Future<RemoteAccount> _startSession(AuthResult result) async {
    await _apiRepositories.tokens.write(result.token);
    _apiRepositories.cache.clear();
    _session++;
    _signIn++;
    _preferences.signedOut = false;

    final account = _toAccount(result.user);
    _keepAccount(account, result.token);

    // A slow FCM must not hold the sign-in; the errors are logged.
    unawaited(_startFcmSync(_signIn));
    _changes.add(null);

    return account;
  }

  /// Sends the FCM token now and each time it changes, for as long as the
  /// sign-in [session] lasts
  Future<void> _startFcmSync(int session) async {
    try {
      if (session != _signIn) return;

      _fcmRefreshes ??= _messaging.tokenRefreshes.listen(
        (token) => unawaited(_sendFcmToken(token, session)),
        onError: _logger.error,
      );

      await _sendFcmToken(await _messaging.getUserToken(), session);
    } catch (e, s) {
      _logger.error(e, s);
    }
  }

  /// A token that was asked for in an older session belongs to nobody now:
  /// the request would go out with the token of the next account.
  Future<void> _sendFcmToken(String token, int session) async {
    if (token.isEmpty || session != _signIn) return;

    try {
      await _auth.updateMe(fcmToken: token);
    } catch (e, s) {
      // Without the token the user only gets no invitations.
      _logger.error(e, s);
    }
  }

  /// Uploads the picture of the social network as the avatar of the account
  /// of the sign-in [session]. The requests take the token of whoever is
  /// signed in when they are sent, so the sign-in is checked between the
  /// steps.
  Future<void> _uploadPicture(String pictureUri, int session) async {
    try {
      final repository = _apiRepositories.forUser();
      final picture = await repository.downloadPicture(pictureUri);
      if (session != _signIn) return;

      await repository.putAvatar(picture);

      // Another account signed in meanwhile: its avatar stays as it is
      if (session == _signIn) invalidate();
    } catch (e, s) {
      _logger.error(e, s);
    }
  }

  RemoteAccount _toAccount(LpsUser user) => RemoteAccount(
    user,
    avatarUrl: user.avatarUrl(_apiRepositories.serverConfig),
    canReceiveMessages: _preferences.onlineChatEnabled,
  );

  void _keepAccount(RemoteAccount account, String token) {
    _account = account;
    _accountTime = _clock();
    _accountToken = token;
  }

  void _forgetAccount() {
    _account = null;
    _accountTime = null;
    _accountToken = null;
  }
}
