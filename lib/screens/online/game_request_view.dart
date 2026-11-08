import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/bloc/states.dart';
import 'package:lets_play_cities/base/remote/bloc/game_request_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/game_request_exception.dart';
import 'package:lets_play_cities/base/remote/bloc/game_request_models.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/remote/usecase/fetch_opponent_profile.dart';
import 'package:lets_play_cities/remote/usecase/handle_request_result.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// First authenticates user in system and then shows game request
class GameRequestView extends StatelessWidget with NetworkAvatarBuildingMixin {
  final GameRequest request;

  const GameRequestView({super.key, required this.request});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8.0),
    height: MediaQuery.of(context).size.height * 0.3,
    child: Column(
      children: [
        Text(
          context.t.online.invitationFrom(login: request.login),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Expanded(
          // Created once and closed with the sheet: the sheet rebuilds this
          // view while it is dragged or the screen size changes.
          child: BlocProvider<GameRequestBloc>(
            create: (_) => GameRequestBloc(
              FetchOpponentProfileUseCase(
                GetIt.instance.get<AccountManager>(),
                () => GetIt.instance.get<ApiRepositoryFactory>(),
              ),
              // A LAN game registers its own AccountManager and
              // ApiRepositoryFactory in a GetIt scope, so the decline looks
              // them up when it is sent.
              HandleRequestResultUseCase(
                () => GetIt.instance.get<AccountManager>(),
                () => GetIt.instance.get<ApiRepositoryFactory>(),
              ),
              GetIt.instance.get<ErrorLogger>(),
            )..add(InputGameRequestEvent(request)),
            child:
                BlocConsumer<GameRequestBloc, BaseState<BaseGameRequestData>>(
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

                    return Center(child: Text('...'));
                  },
                  listener: (context, state) {
                    if (state is DataState<GameRequestProcessingResult>) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GameWaitingRoomScreenStandalone(
                            request: state.data.request,
                            isLocal: false,
                          ),
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
      SizedBox(width: 42.0, height: 42.0, child: CircularProgressIndicator()),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(context.t.online.loading),
      ),
    ],
  );

  Widget _buildErrorView(RequestFailReason failReason, BuildContext context) {
    switch (failReason) {
      case RequestFailReason.notLogged:
        return Center(
          child: Text(
            context.t.online.acceptFailedNotSignedIn,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        );
      case RequestFailReason.networkError:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 42.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(context.t.online.loadingError),
            ),
          ],
        );
      case RequestFailReason.wrongAccount:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.userSlash, size: 42.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(context.t.online.wrongAccount),
            ),
          ],
        );
      case RequestFailReason.exception:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.triangleExclamation, size: 42.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(context.t.online.unknownError),
            ),
          ],
        );
      case RequestFailReason.declinedByUser:
        return Center(child: Text(context.t.online.requestDeclined));
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => context.read<GameRequestBloc>().add(
                  GameRequestResultEvent(RequestResult.declined),
                ),
                child: Text(context.t.decline),
              ),
              ElevatedButton(
                onPressed: () => context.read<GameRequestBloc>().add(
                  GameRequestResultEvent(RequestResult.accepted),
                ),
                child: Text(context.t.accept),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
