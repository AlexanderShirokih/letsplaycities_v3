import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';

/// Checks input words for existing in exclusions list.
/// Emits [Exclusion] if word contains in exclusion lists.
class ExclusionsChecker extends TypedEventHandler<RawWordEvent> {
  final ExclusionsService _exclusionsService;

  ExclusionsChecker(this._exclusionsService);

  @override
  Stream<GameEvent> processTypedEvent(RawWordEvent event) async* {
    // Check the city in the exclusions list
    var exclusion = _exclusionsService.checkForExclusion(event.word);
    yield exclusion.isNotEmpty ? Exclusion(exclusion) : event;
  }
}
