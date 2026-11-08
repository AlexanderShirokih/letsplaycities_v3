import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/service_events_bloc.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/i18n/time_format.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';

import 'combo_badge.dart';
import 'user_avatar.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(10.0, 40.0, 10.0, 24.0),
    color: Theme.of(context).primaryColor,
    child: RepositoryProvider<GameServiceEventsRepository>(
      create: (context) => context
          .read<GameSessionRepository>()
          .createGameServiceEventsRepository(),
      child: Builder(
        builder: (context) {
          final repo = context.watch<GameSessionRepository>();
          final leftUser = repo.getUserByPosition(Position.left);
          final rightUser = repo.getUserByPosition(Position.right);
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  UserAvatar(user: leftUser),
                  _ActionButtons(repo),
                  UserAvatar(user: rightUser),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ComboBadgeWidget(leftUser.comboSystem.eventStream),
                  ComboBadgeWidget(rightUser.comboSystem.eventStream),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _ActionButtons extends StatelessWidget {
  final GameSessionRepository _gameSessionRepository;

  const _ActionButtons(this._gameSessionRepository);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _createActionButton(
                context,
                FontAwesomeIcons.bars,
                confirmationMessage: t.game.goToMenu,
                onConfirmed: () => Navigator.of(context).pop(),
              ),
              _createActionButton(
                context,
                FontAwesomeIcons.flag,
                confirmationMessage: t.game.surrender,
                onConfirmed: () =>
                    context.read<GameBloc>().add(const GameEventSurrender()),
              ),
              if (_gameSessionRepository.helpAvailable)
                _createActionButton(
                  context,
                  FontAwesomeIcons.lightbulb,
                  confirmationMessage: t.game.showHelp,
                  onConfirmed: () =>
                      context.read<GameBloc>().add(const GameEventShowHelp()),
                ),
              if (_gameSessionRepository.messagingAvailable)
                _createActionButton(
                  context,
                  FontAwesomeIcons.envelope,
                  onConfirmed: () => context.read<ServiceEventsBloc>().add(
                    ServiceEventsEvent.toggleMessageField,
                  ),
                ),
            ],
          ),
          SizedBox(width: 0.0, height: 16.0),
          StreamBuilder<int>(
            stream: context
                .watch<GameServiceEventsRepository>()
                .getTimerTicks(),
            builder: (context, snapshot) {
              return Text(
                snapshot.hasData
                    ? formatMinutesSeconds(t, snapshot.requireData)
                    : '',
                style: Theme.of(context).textTheme.titleLarge,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _createActionButton(
    BuildContext context,
    FaIconData faIconData, {
    String? confirmationMessage,
    required VoidCallback onConfirmed,
  }) => SizedBox(
    width: 56.0,
    height: 56.0,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        padding: const EdgeInsets.all(10.0),
        shape: StadiumBorder(side: BorderSide(color: Colors.white, width: 3.0)),
      ),
      onPressed: () => confirmationMessage == null
          ? onConfirmed()
          : showConfirmationDialog(
              context,
              message: confirmationMessage,
              onOk: onConfirmed,
            ),
      child: FaIcon(faIconData, color: Colors.white),
    ),
  );
}
