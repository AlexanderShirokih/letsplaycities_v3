import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/bloc/states.dart';
import 'package:lets_play_cities/base/remote/bloc/game_request_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/game_request_exception.dart';
import 'package:lets_play_cities/base/remote/bloc/game_request_models.dart';
import 'package:lets_play_cities/base/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

const _request = GameRequest('Alice', 2, 1);

final _requester = ProfileInfo(
  userId: 2,
  login: 'Alice',
  pictureUrl: null,
  role: Role.regular,
  lastVisitDate: DateTime(2026, 1, 1),
  banStatus: BanStatus.notBanned,
  friendshipStatus: FriendshipStatus.friends,
  authType: AuthType.native,
);

/// Returns [_requester], or throws [error] when it is set.
class _FakeProfileFetch
    implements SingleAsyncUseCase<GameRequest, ProfileInfo> {
  Object? error;

  @override
  Future<ProfileInfo> execute(GameRequest request) async {
    final error = this.error;
    if (error != null) throw error;
    return _requester;
  }
}

class _FakeResultHandler
    implements
        PairedAsyncUseCase<GameRequest, RequestResult, FriendGameRequest?> {
  final calls = <(GameRequest, RequestResult)>[];

  @override
  Future<FriendGameRequest?> execute(
    GameRequest request,
    RequestResult result,
  ) async {
    calls.add((request, result));
    return result == RequestResult.accepted
        ? FriendGameRequest(
            target: request.requester,
            mode: FriendGameRequestType.join,
          )
        : null;
  }
}

class _RecordingLogger implements ErrorLogger {
  final messages = <String>[];

  @override
  void log(String message) => messages.add(message);

  @override
  void error(Object error, StackTrace stackTrace) => messages.add('$error');
}

void main() {
  late _FakeProfileFetch profileFetch;
  late _FakeResultHandler resultHandler;
  late _RecordingLogger logger;
  late GameRequestBloc bloc;
  late List<BaseState<BaseGameRequestData>> states;

  setUp(() {
    profileFetch = _FakeProfileFetch();
    resultHandler = _FakeResultHandler();
    logger = _RecordingLogger();
    bloc = GameRequestBloc(profileFetch, resultHandler, logger);
    states = [];
    bloc.stream.listen(states.add);
  });

  tearDown(() => bloc.close());

  Future<void> send(GameRequestEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  RequestFailReason? failReasonOf(BaseState<BaseGameRequestData> state) =>
      state is ErrorState<BaseGameRequestData>
      ? (state.exception as GameRequestException).failReason
      : null;

  test('accepting a shown request opens the game with the requester', () async {
    await send(const InputGameRequestEvent(_request));
    expect(states.last, isA<DataState<GotInputGameRequest>>());

    await send(const GameRequestResultEvent(RequestResult.accepted));

    expect(resultHandler.calls, [(_request, RequestResult.accepted)]);
    final result = states.last;
    expect(result, isA<DataState<GameRequestProcessingResult>>());
    final processed = (result as DataState<GameRequestProcessingResult>).data;
    expect(processed.request.target, _request.requester);
    expect(logger.messages, isEmpty);
  });

  test('declining a shown request sends the answer and closes', () async {
    await send(const InputGameRequestEvent(_request));
    await send(const GameRequestResultEvent(RequestResult.declined));

    expect(resultHandler.calls, [(_request, RequestResult.declined)]);
    expect(failReasonOf(states.last), RequestFailReason.declinedByUser);
  });

  test('a result without a shown request is reported as an error', () async {
    await send(const GameRequestResultEvent(RequestResult.accepted));

    expect(resultHandler.calls, isEmpty);
    expect(failReasonOf(states.last), RequestFailReason.exception);
    expect(logger.messages, hasLength(1));
  });

  test('a second answer after the request was handled is not sent', () async {
    await send(const InputGameRequestEvent(_request));
    await send(const GameRequestResultEvent(RequestResult.accepted));
    await send(const GameRequestResultEvent(RequestResult.declined));

    expect(resultHandler.calls, [(_request, RequestResult.accepted)]);
    expect(failReasonOf(states.last), RequestFailReason.exception);
    expect(logger.messages, hasLength(1));
  });

  for (final (error, reason) in [
    (AuthorizationException('signed out'), RequestFailReason.notLogged),
    (const WrongAccountException(), RequestFailReason.wrongAccount),
    (const RemoteException('offline'), RequestFailReason.networkError),
  ]) {
    test('a request failing with ${error.runtimeType} shows $reason', () async {
      profileFetch.error = error;

      await send(const InputGameRequestEvent(_request));

      expect(failReasonOf(states.last), reason);
      expect(logger.messages, isEmpty);
    });
  }
}
