import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';

import '../../../screens/online/online_fakes.dart';

void main() {
  late FakeApiRepository repository;
  late FakeAchievementsService achievements;
  late UserActionsBloc bloc;
  late List<UserActionsState> states;

  final unban = UserEvent(
    lpsUser(1, 'Bob'),
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
    expect(repository.log, ['deleteBlock(1)']);
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

  UserEvent answer(UserUserAction action) =>
      UserEvent(lpsUser(2, 'Ann'), action, confirmationMessage: 'done');

  test('an accepted friend request unlocks add1Friend', () async {
    await send(answer(UserUserAction.acceptRequest));

    expect(repository.log, ['putFriend(2)']);
    expect(achievements.unlocked, [Achievement.add1Friend]);
  });

  test('a declined friend request unlocks nothing', () async {
    await send(answer(UserUserAction.declineRequest));

    expect(repository.log, ['deleteFriend(2)']);
    expect(achievements.unlocked, isEmpty);
  });

  test('a failed acceptance unlocks nothing', () async {
    repository.actionError = StateError('offline');

    await send(answer(UserUserAction.acceptRequest));

    expect(states.last, isA<UserActionErrorState>());
    expect(achievements.unlocked, isEmpty);
  });

  const wire = {
    UserUserAction.addToFriends: 'putFriend(2)',
    UserUserAction.removeFromFriends: 'deleteFriend(2)',
    UserUserAction.cancelRequest: 'deleteFriend(2)',
    UserUserAction.declineRequest: 'deleteFriend(2)',
    UserUserAction.acceptRequest: 'putFriend(2)',
    UserUserAction.banUser: 'putBlock(2)',
    UserUserAction.unbanUser: 'deleteBlock(2)',
  };
  for (final MapEntry(key: action, value: call) in wire.entries) {
    test('$action calls $call', () async {
      await send(answer(action));

      expect(repository.log, [call]);
    });
  }
}
