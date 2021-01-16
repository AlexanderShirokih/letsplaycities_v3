import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/remote/bloc/avatar_bloc.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/remote/api_repository.dart';

/// Used to update or delete user avatar
class AvatarChooserView extends StatelessWidget {
  final LocalizationService l10n;
  final AvatarBloc _avatarBloc;
  final VoidCallback onAvatarUpdated;

  AvatarChooserView(
    this.l10n,
    ApiRepository apiRepository, {
    required this.onAvatarUpdated,
  }) : _avatarBloc = AvatarBloc(apiRepository);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocConsumer<AvatarBloc, AvatarState>(
        value: _avatarBloc,
        builder: (context, state) {
          if (state is AvatarLoadingState) {
            return Container(
              alignment: Alignment.center,
              width: 64,
              height: 64,
              child: CircularProgressIndicator(),
            );
          } else {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildItem(FontAwesomeIcons.images, l10n.misc['gallery'],
                    AvatarEvent.PickGalleryAvatarEvent),
                _buildItem(FontAwesomeIcons.camera, l10n.misc['camera'],
                    AvatarEvent.PickCameraAvatarEvent),
                _buildItem(FontAwesomeIcons.trash, l10n.delete,
                    AvatarEvent.RemoveAvatarEvent),
              ],
            );
          }
        },
        listener: (context, state) {
          if (state is AvatarDoneState) {
            if (state.updateRequired) onAvatarUpdated();
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, AvatarEvent event) {
    return ListTile(
      leading: FaIcon(icon),
      title: Text(title),
      onTap: () => _avatarBloc.add(event),
    );
  }
}
