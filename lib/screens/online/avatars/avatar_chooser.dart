import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/avatar_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';

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
  late final AvatarBloc _avatarBloc = AvatarBloc(
    widget.apiRepository,
    GetIt.instance.get<AccountManager>(),
  );

  @override
  void dispose() {
    _avatarBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);

    return SafeArea(
      child: BlocConsumer<AvatarBloc, AvatarState>(
        bloc: _avatarBloc,
        builder: (context, state) {
          if (state is AvatarLoadingState) {
            return Container(
              alignment: Alignment.center,
              width: 64,
              height: 64,
              child: CircularProgressIndicator(color: c.violet),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                  child: Text(
                    t.online.avatarTitle,
                    style: AppText.title.copyWith(color: c.ink),
                  ),
                ),
                _buildItem(
                  AppGlyph.gallery,
                  t.misc.gallery,
                  AvatarEvent.pickGalleryAvatarEvent,
                ),
                _buildItem(
                  AppGlyph.camera,
                  t.misc.camera,
                  AvatarEvent.pickCameraAvatarEvent,
                ),
                _buildItem(
                  AppGlyph.trash,
                  t.delete,
                  AvatarEvent.removeAvatarEvent,
                  destructive: true,
                ),
              ],
            ),
          );
        },
        listener: (context, state) {
          if (state is AvatarDoneState) {
            if (state.error != null) {
              final apiError = state.apiError;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    apiError == null
                        ? t.online.avatarChangeFailed
                        : errorText(t, apiError),
                  ),
                ),
              );
            }
            if (state.updateRequired) widget.onAvatarUpdated();
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildItem(
    AppGlyph icon,
    String title,
    AvatarEvent event, {
    bool destructive = false,
  }) {
    final c = AppColors.of(context);
    final color = destructive ? c.error : c.ink;

    return InkWell(
      onTap: () => _avatarBloc.add(event),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: destructive ? c.error.withValues(alpha: 0.12) : c.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: AppIcon(icon, size: 22, color: color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: AppText.body.copyWith(color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
