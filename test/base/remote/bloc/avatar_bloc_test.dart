import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/remote/bloc/avatar_bloc.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';

import '../../../screens/online/online_fakes.dart';

void main() {
  late FakeApiRepository repository;
  late AvatarBloc bloc;
  late FakeAccountManager accounts;
  late List<AvatarState> states;

  setUp(() {
    repository = FakeApiRepository();
    accounts = FakeAccountManager(null);
    bloc = AvatarBloc(repository, accounts);
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
    expect(repository.log, ['deleteAvatar()']);
    expect(accounts.invalidations, 1);
  });

  test('a failed removal ends with an error instead of loading', () async {
    repository.actionError = Exception('offline');

    await removeAvatar();

    expect(states.first, AvatarLoadingState());
    final done = states.last;
    expect(done, isA<AvatarDoneState>());
    expect((done as AvatarDoneState).updateRequired, isFalse);
    expect(done.error, contains('offline'));
    expect(accounts.invalidations, 0);
  });

  test('a refused picture ends with the answer of the server', () async {
    const refusal = ApiException(400, 'bad_image', 'Bad picture');
    repository.actionError = refusal;

    await removeAvatar();

    expect((states.last as AvatarDoneState).apiError, refusal);
  });
}
