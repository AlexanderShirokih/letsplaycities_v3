import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/server/usecase/signup_user.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'signup_user_test.mocks.dart';

/// [HttpRequest] whose body arrives in the given chunks.
class _FakeRequest extends Stream<Uint8List> implements HttpRequest {
  _FakeRequest(this._chunks, this.response);

  final List<List<int>> _chunks;

  @override
  final HttpResponse response;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream.fromIterable(_chunks.map(Uint8List.fromList)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<int> _signUpBody(String login) => utf8.encode(
  jsonEncode(
    RemoteSignUpData(
      accessToken: '',
      snUID: '',
      firebaseToken: '',
      login: login,
      authType: AuthType.native,
    ).toMap(),
  ),
);

@GenerateNiceMocks([
  MockSpec<SingleUseCase<RemoteSignUpData, ProfileInfo>>(
    as: #MockGetProfileFromSignUpInfo,
  ),
  MockSpec<HttpRequest>(),
  MockSpec<HttpResponse>(),
  MockSpec<HttpHeaders>(),
])
void main() {
  late SingleAsyncUseCase<HttpRequest, void> useCase;
  late MockGetProfileFromSignUpInfo getProfileFromSignUpInfo;
  late HttpRequest request;
  late HttpResponse response;
  late HttpHeaders headers;
  late ProfileInfo profileInfo;

  setUp(() {
    headers = MockHttpHeaders();
    response = MockHttpResponse();

    profileInfo = ProfileInfo(
      userId: 1,
      login: 'test',
      pictureUrl: '',
      role: Role.regular,
      lastVisitDate: DateTime.now(),
      banStatus: BanStatus.notBanned,
      friendshipStatus: FriendshipStatus.notFriends,
      authType: AuthType.native,
    );

    request = _FakeRequest([_signUpBody('')], response);
    when(response.headers).thenReturn(headers);

    getProfileFromSignUpInfo = MockGetProfileFromSignUpInfo();
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

  test('Reads a body that arrives in several chunks', () async {
    final body = _signUpBody('Игрок');
    // Split inside the two-byte UTF-8 sequence of a Cyrillic letter
    final split = body.indexOf(0xD0) + 1;
    request = _FakeRequest([
      body.sublist(0, split),
      body.sublist(split),
    ], response);

    await useCase.execute(request);

    final signUpData =
        verify(getProfileFromSignUpInfo.execute(captureAny)).captured.single
            as RemoteSignUpData;
    expect(signUpData.login, equals('Игрок'));
    verify(response.close()).called(1);
  });
}
