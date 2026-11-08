import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

import '../../../screens/online/online_fakes.dart';

void main() {
  late FakeApiRepository repository;
  late FakeAchievementsService achievements;
  late UserActionsBloc bloc;
  late List<UserActionsState> states;

  const unban = UserEvent(
    BaseProfileInfo(userId: 1, login: 'Bob'),
    UserUserAction.unbanUser,
    confirmationMessage: 'removed',
    undoable: true,
  );

  setUp(() {
    repository = FakeApiRepository();
    achievements = FakeAchievementsService();
    bloc = UserActionsBloc(repository, achievements);
    states = [];
    bloc.stream.listen(states.add);
  });

  tearDown(() => bloc.close());

  Future<void> send(UserActionsEvent event) async {
    bloc.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  test('an undoable action runs only after it is confirmed', () async {
    await send(unban);
    expect(states, [UserActionConfirmationState(unban)]);
    expect(repository.log, isEmpty);

    await send(UserActionConfirmedEvent(unban));
    expect(states.skip(1), [
      UserProcessingActionState(),
      UserActionDoneState(unban),
    ]);
    expect(repository.log, ['removeFromBanlist(1)']);
  });

  test('after a reset the same undoable action asks again', () async {
    await send(unban);
    await send(const UserActionsResetEvent());
    await send(unban);

    expect(states, [
      UserActionConfirmationState(unban),
      UserActionsInitial(),
      UserActionConfirmationState(unban),
    ]);
    expect(repository.log, isEmpty);
  });

  UserEvent answer(UserUserAction action) => UserEvent(
    const BaseProfileInfo(userId: 2, login: 'Ann'),
    action,
    confirmationMessage: 'done',
  );

  test('an accepted friend request unlocks add1Friend', () async {
    await send(answer(UserUserAction.acceptRequest));

    expect(repository.log, ['sendFriendRequestAcceptance(2, true)']);
    expect(achievements.unlocked, [Achievement.add1Friend]);
  });

  test('a declined friend request unlocks nothing', () async {
    await send(answer(UserUserAction.declineRequest));

    expect(repository.log, ['sendFriendRequestAcceptance(2, false)']);
    expect(achievements.unlocked, isEmpty);
  });

  test('a failed acceptance unlocks nothing', () async {
    repository.actionError = StateError('offline');

    await send(answer(UserUserAction.acceptRequest));

    expect(states.last, isA<UserActionErrorState>());
    expect(achievements.unlocked, isEmpty);
  });
}
