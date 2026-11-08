import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/remote/bloc/avatar_bloc.dart';

import '../../../screens/online/online_fakes.dart';

void main() {
  late FakeApiRepository repository;
  late AvatarBloc bloc;
  late List<AvatarState> states;

  setUp(() {
    repository = FakeApiRepository();
    bloc = AvatarBloc(repository);
    states = [];
    bloc.stream.listen(states.add);
  });

  tearDown(() => bloc.close());

  Future<void> removeAvatar() async {
    bloc.add(AvatarEvent.removeAvatarEvent);
    await Future<void>.delayed(Duration.zero);
  }

  test('removing the avatar asks for a profile update', () async {
    await removeAvatar();

    expect(states, [AvatarLoadingState(), AvatarDoneState(true)]);
  });

  test('a failed removal ends with an error instead of loading', () async {
    repository.actionError = Exception('offline');

    await removeAvatar();

    expect(states.first, AvatarLoadingState());
    final done = states.last;
    expect(done, isA<AvatarDoneState>());
    expect((done as AvatarDoneState).updateRequired, isFalse);
    expect(done.error, contains('offline'));
  });
}
