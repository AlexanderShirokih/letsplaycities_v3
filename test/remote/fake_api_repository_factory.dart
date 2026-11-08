import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Hands out [repository] for every user and records the ids of the users it
/// was asked for.
class FakeApiRepositoryFactory extends Fake implements ApiRepositoryFactory {
  FakeApiRepositoryFactory(this.repository);

  final ApiRepository repository;
  final userIds = <int>[];

  @override
  ApiRepository forUser([int userId = 0]) {
    userIds.add(userId);
    return repository;
  }
}
