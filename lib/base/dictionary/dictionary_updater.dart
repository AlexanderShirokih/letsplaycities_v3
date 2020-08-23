/// [DictionaryUpdater] is responsible for checking dictionary updates and downloading it
/// TODO: Stub implementation
class DictionaryUpdater {
  /// Checks for database updates on game server and downloads it.
  /// If updates disabled or not available no events will be emmited.
  /// When starts fetching update first emits `-1` percent value to indicate
  /// fetching update starts. Emits downloading percents from 0 to 100.
  Stream<int> checkForUpdates() async* {
    // Simulate fetching updates
    yield -1;
    await Future.delayed(Duration(milliseconds: 500));

    // Simulate downloading update
    for (int i = 0; i < 100; i += 10) {
      yield i;
      await Future.delayed(Duration(milliseconds: 100));
    }
  }
}
