import 'dart:convert';
import 'dart:io';

import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

/// Handles sign-up HTTP request
class SignUpUserUsecase
    implements SingleAsyncUseCase<HttpRequest, ProfileInfo> {
  final SingleUseCase<RemoteSignUpData, ProfileInfo> _getProfileFromSignUpInfo;

  SignUpUserUsecase(this._getProfileFromSignUpInfo);

  @override
  Future<ProfileInfo> execute(HttpRequest request) async {
    final rawMessage = await request.single;
    final json = jsonDecode(utf8.decode(rawMessage));
    final signUpData = RemoteSignUpData.fromMap(json);
    final profile = _getProfileFromSignUpInfo.execute(signUpData);

    final response = RemoteSignUpResponse(
      login: profile.login,
      authType: profile.authType,
      userId: profile.userId,
      role: Role.regular,
      accessToken: '',
      pictureHash: '',
    );

    // Send authorization response
    final encodedResponse = jsonEncode({'data': response.toMap()});

    request.response
      ..headers.contentType = ContentType.json
      ..write(encodedResponse);

    await request.response.close();

    return profile;
  }
}
