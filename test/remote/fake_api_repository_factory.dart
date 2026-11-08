import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Hands out [repository] for every credential and records the credentials
/// it was asked for.
class FakeApiRepositoryFactory extends Fake implements ApiRepositoryFactory {
  FakeApiRepositoryFactory(this.repository);

  final ApiRepository repository;
  final credentials = <Credential>[];

  @override
  ApiRepository forCredential(Credential credential) {
    credentials.add(credential);
    return repository;
  }
}
