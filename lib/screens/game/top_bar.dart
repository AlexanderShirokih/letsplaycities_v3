import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';

import 'combo_badge.dart';
import 'user_avatar.dart';

class TopBar extends StatelessWidget {
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
              final leftUser = repo.getUserByPosition(Position.LEFT);
              final rightUser = repo.getUserByPosition(Position.RIGHT);
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      UserAvatar(
                        onPressed: () {
                          // TODO: Handle left avatar click
                        },
                        user: leftUser,
                      ),
                      _ActionButtons(repo),
                      UserAvatar(
                        onPressed: () {
                          // TODO: Handle right avatar click
                        },
                        user: rightUser,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ComboBadgeWidget(
                        leftUser.comboSystem.eventStream,
                      ),
                      ComboBadgeWidget(
                        rightUser.comboSystem.eventStream,
                      )
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

  _ActionButtons(this._gameSessionRepository);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _createActionButton(context, FontAwesomeIcons.bars,
                    confirmationMessageKey: 'go_to_menu',
                    onConfirmed: () => Navigator.of(context).pop()),
                _createActionButton(context, FontAwesomeIcons.flag,
                    confirmationMessageKey: 'surrender',
                    onConfirmed: () => context
                        .read<GameBloc>()
                        .add(const GameEventSurrender())),
                if (_gameSessionRepository.helpAvailable)
                  _createActionButton(context, FontAwesomeIcons.lightbulb,
                      confirmationMessageKey: 'show_help',
                      onConfirmed: () => context
                          .read<GameBloc>()
                          .add(const GameEventShowHelp())),
                if (_gameSessionRepository.messagingAvailable)
                  _createActionButton(context, FontAwesomeIcons.envelope,
                      onConfirmed: () {
                    // TODO: Send message
                  }),
              ],
            ),
            SizedBox(width: 0.0, height: 16.0),
            StreamBuilder<String>(
                stream: context
                    .watch<GameServiceEventsRepository>()
                    .getTimerTicks(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.hasData ? snapshot.data : '',
                    style: Theme.of(context).textTheme.headline6,
                  );
                }),
          ],
        ),
      );

  Widget _createActionButton(BuildContext context, IconData faIconData,
          {String confirmationMessageKey, @required Function onConfirmed}) =>
      Container(
        width: 56.0,
        height: 56.0,
        child: RaisedButton(
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.all(10.0),
          onPressed: () => confirmationMessageKey == null
              ? onConfirmed()
              : showConfirmationDialog(
                  context,
                  message: context
                      .read<LocalizationService>()
                      .game[confirmationMessageKey],
                  onOk: onConfirmed,
                ),
          child: FaIcon(faIconData, color: Colors.white),
          shape:
              StadiumBorder(side: BorderSide(color: Colors.white, width: 3.0)),
        ),
      );
}
