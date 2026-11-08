import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/remote/bloc/avatar_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository.dart';

/// Used to update or delete user avatar
class AvatarChooserView extends StatefulWidget {
  final ApiRepository apiRepository;
  final VoidCallback onAvatarUpdated;

  const AvatarChooserView(
    this.apiRepository, {
    super.key,
    required this.onAvatarUpdated,
  });

  @override
  State<AvatarChooserView> createState() => _AvatarChooserViewState();
}

class _AvatarChooserViewState extends State<AvatarChooserView> {
  // Lives as long as the sheet: the sheet builds a new view while it is
  // dragged, and a new bloc would lose the upload in progress.
  late final AvatarBloc _avatarBloc = AvatarBloc(widget.apiRepository);

  @override
  void dispose() {
    _avatarBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SafeArea(
      child: BlocConsumer<AvatarBloc, AvatarState>(
        bloc: _avatarBloc,
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
                _buildItem(
                  FontAwesomeIcons.images,
                  t.misc.gallery,
                  AvatarEvent.pickGalleryAvatarEvent,
                ),
                _buildItem(
                  FontAwesomeIcons.camera,
                  t.misc.camera,
                  AvatarEvent.pickCameraAvatarEvent,
                ),
                _buildItem(
                  FontAwesomeIcons.trash,
                  t.delete,
                  AvatarEvent.removeAvatarEvent,
                ),
              ],
            );
          }
        },
        listener: (context, state) {
          if (state is AvatarDoneState) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.online.avatarChangeFailed)),
              );
            }
            if (state.updateRequired) widget.onAvatarUpdated();
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildItem(FaIconData icon, String title, AvatarEvent event) {
    return ListTile(
      leading: FaIcon(icon),
      title: Text(title),
      onTap: () => _avatarBloc.add(event),
    );
  }
}
