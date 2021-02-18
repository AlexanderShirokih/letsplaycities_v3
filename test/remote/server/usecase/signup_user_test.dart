//@dart=2.9

import 'dart:convert';
import 'dart:io';

import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/remote/server/usecase/signup_user.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _MockGetProfileFromSignUpInfo extends Mock
    implements SingleUseCase<RemoteSignUpData, ProfileInfo> {}

class _MockHttpRequest extends Mock implements HttpRequest {}

class _MockHttpResponse extends Mock implements HttpResponse {}

class _MockHttpHeaders extends Mock implements HttpHeaders {}

void main() {
  SingleAsyncUseCase<HttpRequest, void> useCase;
  HttpRequest request;
  HttpResponse response;
  HttpHeaders headers;
  ProfileInfo profileInfo;

  setUp(() {
    headers = _MockHttpHeaders();
    request = _MockHttpRequest();
    response = _MockHttpResponse();

    profileInfo = ProfileInfo(
      userId: 1,
      login: 'test',
      pictureUrl: '',
      role: Role.regular,
      lastVisitDate: DateTime.now(),
      banStatus: BanStatus.notBanned,
      friendshipStatus: FriendshipStatus.notFriends,
      authType: AuthType.Native,
    );

    when(request.single).thenAnswer((_) async {
      return utf8.encode(
        jsonEncode(
          RemoteSignUpData(
            accessToken: '',
            snUID: '',
            firebaseToken: '',
            login: '',
            authType: AuthType.Native,
          ).toMap(),
        ),
      );
    });
    when(response.headers).thenReturn(headers);
    when(request.response).thenReturn(response);

    final getProfileFromSignUpInfo = _MockGetProfileFromSignUpInfo();
    when(getProfileFromSignUpInfo.execute(any)).thenReturn(profileInfo);

    useCase = SignUpUserUsecase(getProfileFromSignUpInfo);
  });

  test('Request completes normally', () async {
    await expectLater(useCase.execute(request), completes);
  });

  test('Response has sent and request closed', () async {
    await useCase.execute(request);

    verify(response.write(any)).called(greaterThanOrEqualTo(1));
    verify(response.close()).called(1);
  });
}
