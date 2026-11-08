import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/user_list_actions_bloc.dart';
import 'package:lets_play_cities/remote/model/social.dart';

import '../../../screens/online/online_fakes.dart';

void main() {
  late FakeApiRepository repository;
  late UserListActionsBloc bloc;

  HistoryGame game(int id) => HistoryGame(
    id: id,
    opponent: lpsUser(2, 'Alice'),
    isFriend: false,
    startedAt: DateTime(2026, 1, 1),
    durationSec: 60,
    words: 10,
  );

  setUp(() {
    repository = FakeApiRepository()
      ..pageSize = 2
      ..games = [for (var id = 5; id >= 1; id--) game(id)];
    bloc = UserListActionsBloc(
      repository,
      UserFetchType.getHistoryList,
      withUser: 2,
    );
  });

  tearDown(() => bloc.close());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  List<int> ids() => [
    for (final g in (bloc.state as UserActionListDataState).data)
      (g as HistoryGame).id,
  ];

  test('history pages follow next', () async {
    await settle();
    expect(ids(), [5, 4]);
    expect((bloc.state as UserActionListDataState).hasMore, isTrue);

    bloc.add(const UserFetchMoreEvent());
    await settle();
    expect(ids(), [5, 4, 3, 2]);

    bloc.add(const UserFetchMoreEvent());
    await settle();
    expect(ids(), [5, 4, 3, 2, 1]);
    expect((bloc.state as UserActionListDataState).hasMore, isFalse);

    // On the last page there is nothing more to ask for
    bloc.add(const UserFetchMoreEvent());
    await settle();
    expect(repository.historyCalls, [
      'history(withUser: 2, before: null)',
      'history(withUser: 2, before: 4)',
      'history(withUser: 2, before: 2)',
    ]);
  });

  test('a refresh starts the history from the first page again', () async {
    await settle();
    bloc.add(const UserFetchMoreEvent());
    await settle();

    bloc.add(const UserFetchListEvent(true));
    await settle();

    expect(ids(), [5, 4]);
  });

  test('a failed page keeps the loaded games and can be retried', () async {
    await settle();

    repository.listError = StateError('offline');
    bloc.add(const UserFetchMoreEvent());
    await settle();

    var state = bloc.state as UserActionListDataState;
    expect(ids(), [5, 4]);
    expect(state.moreError, isA<StateError>());
    expect(state.hasMore, isTrue);

    repository.listError = null;
    bloc.add(const UserFetchMoreEvent());
    await settle();

    state = bloc.state as UserActionListDataState;
    expect(ids(), [5, 4, 3, 2]);
    expect(state.moreError, isNull);
  });

  test('the first request skips the cache only when asked to', () async {
    final friends = UserListActionsBloc(
      repository,
      UserFetchType.getFriendsList,
      refreshOnOpen: true,
    );
    addTearDown(friends.close);
    await settle();

    expect(repository.log, ['friends(forceRefresh: true)']);
  });
}
