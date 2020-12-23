import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lets_play_cities/remote/api_repository.dart';

part 'avatar_event.dart';

part 'avatar_state.dart';

/// BLoc that handles user picture actions
class AvatarBloc extends Bloc<AvatarEvent, AvatarState> {
  final picker = ImagePicker();
  final ApiRepository _apiRepository;

  AvatarBloc(this._apiRepository)
      : assert(_apiRepository != null),
        super(AvatarInitial());

  @override
  Stream<AvatarState> mapEventToState(
    AvatarEvent event,
  ) async* {
    switch (event) {
      case AvatarEvent.RemoveAvatarEvent:
        yield* removeImage();
        break;
      case AvatarEvent.PickGalleryAvatarEvent:
        yield* getImage(ImageSource.gallery);
        break;
      case AvatarEvent.PickCameraAvatarEvent:
        yield* getImage(ImageSource.camera);
        break;
    }

    yield AvatarDoneState();
  }

  Stream<AvatarState> getImage(ImageSource source) async* {
    final pickedFile = await picker.getImage(source: source);

    if (pickedFile != null) {
      await _apiRepository.updatePicture(pickedFile.readAsBytes());
    }
  }

  Stream<AvatarState> removeImage() async* {
    await _apiRepository.removePicture();
  }
}
