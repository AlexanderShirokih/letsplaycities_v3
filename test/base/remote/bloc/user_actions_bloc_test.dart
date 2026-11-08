import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

import '../../../screens/online/online_fakes.dart';

void main() {
  late FakeApiRepository repository;
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
    bloc = UserActionsBloc(repository);
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
}
