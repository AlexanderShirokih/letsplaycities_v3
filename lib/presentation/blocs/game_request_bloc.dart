import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/data/models/friend_game_request.dart';
import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/presentation/states.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import '../exceptions/game_request_exception.dart';
import '../models/game_request_models.dart';

part 'game_request_event.dart';

/// BloC for handling Friend-mode requests
class GameRequestBloc
    extends Bloc<GameRequestEvent, BaseState<BaseGameRequestData>> {
  /// Use case that checks all requirements and fetches requester [ProfileInfo].
  final SingleAsyncUseCase<GameRequest, ProfileInfo> _inputRequestProcessor;

  /// Use case that handles game request result
  final PairedAsyncUseCase<GameRequest, RequestResult, FriendGameRequest?>
      _requestResultProcessor;

  final ErrorLogger _logger = GetIt.instance.get<ErrorLogger>();

  GameRequestBloc(
    this._inputRequestProcessor,
    this._requestResultProcessor,
  ) : super(InitialState());

  @override
  Stream<BaseState<BaseGameRequestData>> mapEventToState(
      GameRequestEvent event) async* {
    if (event is InputGameRequestEvent) {
      yield* _handleInputRequest(event.request);
    } else if (event is GameRequestResultEvent) {
      yield* _handleRequestResult(event.result);
    }
  }

  Stream<BaseState<BaseGameRequestData>> _handleInputRequest(
      GameRequest request) async* {
    try {
      yield LoadingState();

      // Fetch profile
      final profile = await _inputRequestProcessor.execute(request);

      // All done ok, show request dialog
      yield DataState<GotInputGameRequest>(
          GotInputGameRequest(request, profile));
    } on AuthorizationException {
      // User is not logged in currently.
      yield ErrorState(GameRequestException(RequestFailReason.notLogged));
    } on WrongAccountException {
      // User is logged in, but in another account.
      yield ErrorState(GameRequestException(RequestFailReason.wrongAccount));
    } on RemoteException {
      // Some network exception happened
      yield ErrorState(GameRequestException(RequestFailReason.networkError));
    }
  }

  Stream<BaseState<BaseGameRequestData>> _handleRequestResult(
      RequestResult result) async* {
    if (state is DataState<BaseGameRequestData>) {
      yield LoadingState();

      final request = (state as DataState<GotInputGameRequest>).data.rawRequest;

      try {
        final processedRequest =
            await _requestResultProcessor.execute(request, result);

        if (processedRequest != null) {
          // Positive result: prepare to start waiting room with [processedRequest]
          yield DataState<GameRequestProcessingResult>(
              GameRequestProcessingResult(processedRequest));
        } else {
          // Negative result: close view
          yield ErrorState(
              GameRequestException(RequestFailReason.declinedByUser));
        }
      } on RemoteException {
        // Some network exception happened
        yield ErrorState(GameRequestException(RequestFailReason.networkError));
      }
    } else {
      // Handle unexpected state
      _logger
          .log('Got RequestResult not from GameRequestShowRequestMessageState'
              'current state=${state.runtimeType}');

      yield ErrorState(GameRequestException(RequestFailReason.exception));
    }
  }
}
