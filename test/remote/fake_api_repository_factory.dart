import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Hands out [repository] to the signed-in user.
class FakeApiRepositoryFactory extends Fake implements ApiRepositoryFactory {
  FakeApiRepositoryFactory(this.repository);

  final ApiRepository repository;

  @override
  ApiRepository forUser() => repository;
}
