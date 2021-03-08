import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/domain/game_request/fetch_opponent_profile.dart';
import 'package:lets_play_cities/domain/game_request/handle_request_result.dart';
import 'package:lets_play_cities/presentation/blocs/game_request_bloc.dart';
import 'package:lets_play_cities/presentation/exceptions/game_request_exception.dart';
import 'package:lets_play_cities/presentation/models/game_request_models.dart';
import 'package:lets_play_cities/presentation/states.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';

/// First authenticates user in system and then shows game request
class GameRequestView extends StatelessWidget with NetworkAvatarBuildingMixin {
  final GameRequest request;

  const GameRequestView({Key? key, required this.request}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8.0),
        height: MediaQuery.of(context).size.height * 0.3,
        child: Column(
          children: [
            Text(
              'Приглашение в игру от ${request.login}',
              style: Theme.of(context).textTheme.headline5,
            ),
            Expanded(
              child: BlocProvider<GameRequestBloc>.value(
                value: GameRequestBloc(
                  FetchOpponentProfileUseCase(),
                  HandleRequestResultUseCase(),
                )..add(InputGameRequestEvent(request)),
                child: BlocConsumer<GameRequestBloc,
                    BaseState<BaseGameRequestData>>(
                  builder: (context, state) {
                    if (state is LoadingState<BaseGameRequestData>) {
                      return _buildLoadingView(context);
                    }

                    if (state is ErrorState<BaseGameRequestData>) {
                      return _buildErrorView(
                        (state.exception as GameRequestException).failReason,
                        context,
                      );
                    }

                    if (state is DataState<GotInputGameRequest>) {
                      return _buildRequestView(state.data.requester, context);
                    }

                    return Center(
                      child: Text('...'),
                    );
                  },
                  listener: (context, state) {
                    if (state is DataState<GameRequestProcessingResult>) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameWaitingRoomScreenStandalone(
                              state.data.request),
                        ),
                      );
                    }

                    if (state is ErrorState<BaseGameRequestData>) {
                      final exception = state.exception as GameRequestException;

                      if (exception.failReason ==
                          RequestFailReason.declinedByUser) {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildLoadingView(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 42.0,
            height: 42.0,
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Загрузка...'),
          ),
        ],
      );

  Widget _buildErrorView(RequestFailReason failReason, BuildContext context) {
    switch (failReason) {
      case RequestFailReason.notLogged:
        return Center(
          child: Text(
            'Не удалось принять запрос от пользователя: Вы не авторизованы в аккаунте',
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
        );
      case RequestFailReason.networkError:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 42.0,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Не удалось загрузить данные'),
            )
          ],
        );
      case RequestFailReason.wrongAccount:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.userAltSlash,
              size: 42.0,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Вы получили приглашение от пользователя, '
                  'но сейчас находитесь в другом аккаунте'),
            )
          ],
        );
      case RequestFailReason.exception:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.exclamationTriangle,
              size: 42.0,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Произошла неизвестная ошибка :('),
            )
          ],
        );
      case RequestFailReason.declinedByUser:
        return Center(child: Text('Заявка отклонена'));
    }
  }

  Widget _buildRequestView(ProfileInfo requester, BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.all(10.0),
          leading: buildAvatar(requester, 45.0),
          title: Text(requester.login),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: buildWithLocalization(
            context,
            (l10n) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => context
                      .read<GameRequestBloc>()
                      .add(GameRequestResultEvent(RequestResult.declined)),
                  child: Text(l10n.decline),
                ),
                ElevatedButton(
                  onPressed: () => context
                      .read<GameRequestBloc>()
                      .add(GameRequestResultEvent(RequestResult.accepted)),
                  child: Text(l10n.accept),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}
