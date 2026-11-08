import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:image_picker/image_picker.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';

part 'avatar_event.dart';

part 'avatar_state.dart';

/// BLoc that handles user picture actions
class AvatarBloc extends Bloc<AvatarEvent, AvatarState>
    with SequentialEventMapping<AvatarEvent, AvatarState> {
  final picker = ImagePicker();
  final ApiRepository _apiRepository;
  final AccountManager _accountManager;

  AvatarBloc(this._apiRepository, this._accountManager)
    : super(AvatarInitial()) {
    mapEventsSequentially(_mapEventToState);
  }

  Stream<AvatarState> _mapEventToState(AvatarEvent event) async* {
    switch (event) {
      case AvatarEvent.removeAvatarEvent:
        yield* removeImage();
        break;
      case AvatarEvent.pickGalleryAvatarEvent:
        yield* getImage(ImageSource.gallery);
        break;
      case AvatarEvent.pickCameraAvatarEvent:
        yield* getImage(ImageSource.camera);
        break;
    }
  }

  Stream<AvatarState> getImage(ImageSource source) async* {
    try {
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        yield AvatarLoadingState();
        await _apiRepository.putAvatar(await pickedFile.readAsBytes());
        _accountManager.invalidate();
        yield AvatarDoneState(true);
      } else {
        yield AvatarDoneState();
      }
    } catch (error, stackTrace) {
      yield* _fail(error, stackTrace);
    }
  }

  Stream<AvatarState> removeImage() async* {
    yield AvatarLoadingState();
    try {
      await _apiRepository.deleteAvatar();
      _accountManager.invalidate();
      yield AvatarDoneState(true);
    } catch (error, stackTrace) {
      yield* _fail(error, stackTrace);
    }
  }

  /// Ends the action with an error, so the view stops waiting for it.
  Stream<AvatarState> _fail(Object error, StackTrace stackTrace) async* {
    addError(error, stackTrace);
    yield AvatarDoneState(
      false,
      error.toString(),
      error is ApiException ? error : null,
    );
  }
}
