import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';
import 'package:lets_play_cities/remote/usecase/handle_request_result.dart';

import '../fake_api_repository_factory.dart';

/// Alice (ID 2) invites the user with ID 1.
const _request = GameRequest('Alice', 2, 1);

class _FakeApiRepository extends Fake implements ApiRepository {
  final declined = <BaseProfileInfo>[];

  @override
  Future<void> declineGameRequest(BaseProfileInfo requester) async =>
      declined.add(requester);
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
  late AccountManager accountManager;
  late int accountManagerLookups;
  late int factoryLookups;
  late HandleRequestResultUseCase useCase;

  setUp(() {
    repository = _FakeApiRepository();
    apiRepositories = FakeApiRepositoryFactory(repository);
    accountManager = _FakeAccountManager(_FakeAccount(1));
    accountManagerLookups = 0;
    factoryLookups = 0;
    useCase = HandleRequestResultUseCase(
      () {
        accountManagerLookups++;
        return accountManager;
      },
      () {
        factoryLookups++;
        return apiRepositories;
      },
    );
  });

  test('accepting joins the requester without contacting the server', () async {
    final result = await useCase.execute(_request, RequestResult.accepted);

    expect(result?.target, _request.requester);
    expect(result?.mode, FriendGameRequestType.join);
    expect(accountManagerLookups, 0);
    expect(factoryLookups, 0);
  });

  test('declining sends the decline from the signed-in account', () async {
    final result = await useCase.execute(_request, RequestResult.declined);

    expect(result, isNull);
    expect(repository.declined, [_request.requester]);
    expect(apiRepositories.credentials, [
      const Credential(userId: 1, accessToken: 'token'),
    ]);
  });

  test('declining while signed out throws AuthorizationException', () {
    accountManager = _FakeAccountManager(null);

    expect(
      useCase.execute(_request, RequestResult.declined),
      throwsA(isA<AuthorizationException>()),
    );
  });

  test('looks up the account manager and the factory when the decline is '
      'sent', () async {
    final laterRepository = _FakeApiRepository();
    final laterFactory = FakeApiRepositoryFactory(laterRepository);
    accountManager = _FakeAccountManager(_FakeAccount(5));
    apiRepositories = laterFactory;

    await useCase.execute(_request, RequestResult.declined);

    expect(accountManagerLookups, 1);
    expect(factoryLookups, 1);
    expect(repository.declined, isEmpty);
    expect(laterRepository.declined, [_request.requester]);
    expect(laterFactory.credentials, [
      const Credential(userId: 5, accessToken: 'token'),
    ]);
  });
}
