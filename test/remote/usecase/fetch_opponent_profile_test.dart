import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/usecase/fetch_opponent_profile.dart';

import '../fake_api_repository_factory.dart';

/// Alice (ID 2) invites the user with ID 1.
const _request = GameRequest('Alice', 2, 1);

final _alice = ProfileInfo(
  userId: 2,
  login: 'Alice',
  pictureUrl: null,
  role: Role.regular,
  lastVisitDate: DateTime(2026, 1, 1),
  banStatus: BanStatus.notBanned,
  friendshipStatus: FriendshipStatus.friends,
  authType: AuthType.native,
);

class _FakeApiRepository extends Fake implements ApiRepository {
  final requestedProfiles = <BaseProfileInfo>[];

  @override
  Future<ProfileInfo> getProfileInfo(
    BaseProfileInfo target, [
    bool forceRefresh = false,
  ]) async {
    requestedProfiles.add(target);
    return _alice;
  }
}

class _FakeAccount extends Fake implements RemoteAccount {
  _FakeAccount(int userId)
    : credential = Credential(userId: userId, accessToken: 'token');

  @override
  final Credential credential;
}

class _FakeAccountManager extends Fake implements AccountManager {
  _FakeAccountManager(this.account);

  final RemoteAccount? account;

  @override
  Future<RemoteAccount?> getLastSignedInAccount() async => account;
}

void main() {
  late _FakeApiRepository repository;
  late FakeApiRepositoryFactory apiRepositories;
  late int factoryLookups;

  setUp(() {
    repository = _FakeApiRepository();
    apiRepositories = FakeApiRepositoryFactory(repository);
    factoryLookups = 0;
  });

  FetchOpponentProfileUseCase createUseCase(RemoteAccount? account) =>
      FetchOpponentProfileUseCase(_FakeAccountManager(account), () {
        factoryLookups++;
        return apiRepositories;
      });

  test('fetches the requester profile as the invited account', () async {
    final account = _FakeAccount(1);
    final useCase = createUseCase(account);
    expect(factoryLookups, 0);

    final profile = await useCase.execute(_request);

    expect(profile, _alice);
    expect(repository.requestedProfiles, [_request.requester]);
    expect(apiRepositories.credentials, [account.credential]);
    expect(factoryLookups, 1);
  });

  test('throws AuthorizationException when nobody is signed in', () {
    final useCase = createUseCase(null);

    expect(useCase.execute(_request), throwsA(isA<AuthorizationException>()));
  });

  test('throws WrongAccountException when another account is signed in '
      'and fetches nothing', () async {
    final useCase = createUseCase(_FakeAccount(3));

    await expectLater(
      useCase.execute(_request),
      throwsA(isA<WrongAccountException>()),
    );
    expect(repository.requestedProfiles, isEmpty);
    expect(factoryLookups, 0);
  });
}
