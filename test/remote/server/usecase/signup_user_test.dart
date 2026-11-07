import 'dart:convert';
import 'dart:io';

import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/server/usecase/signup_user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'signup_user_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SingleUseCase<RemoteSignUpData, ProfileInfo>>(
      as: #MockGetProfileFromSignUpInfo),
  MockSpec<HttpRequest>(),
  MockSpec<HttpResponse>(),
  MockSpec<HttpHeaders>(),
])

void main() {
  late SingleAsyncUseCase<HttpRequest, void> useCase;
  late HttpRequest request;
  late HttpResponse response;
  late HttpHeaders headers;
  late ProfileInfo profileInfo;

  setUp(() {
    headers = MockHttpHeaders();
    request = MockHttpRequest();
    response = MockHttpResponse();

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

    final getProfileFromSignUpInfo = MockGetProfileFromSignUpInfo();
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
