import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/utils/online_window.dart';

/// User of the game server: the protocol object `user`
class LpsUser extends Equatable {
  /// How long after [lastSeenAt] a user is shown as online
  static const onlineWindow = userOnlineWindow;

  final int id;
  final String name;

  /// Version of the avatar, `null` if the user has none
  final String? avatarHash;

  /// Origin of the account: `native`, `google`, `vk`, `ok` or `fb`
  final String provider;

  /// Time of the last authorized request of the user
  final DateTime lastSeenAt;

  const LpsUser({
    required this.id,
    required this.name,
    this.avatarHash,
    required this.provider,
    required this.lastSeenAt,
  });

  factory LpsUser.fromJson(Map<String, dynamic> json) {
    final hash = json['avatarHash'] as String?;

    return LpsUser(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarHash: hash == null || hash.isEmpty ? null : hash,
      provider: json['provider'] as String,
      lastSeenAt: DateTime.fromMillisecondsSinceEpoch(
        json['lastSeenAt'] as int,
      ),
    );
  }

  /// `true` while less than [onlineWindow] passed since [lastSeenAt]
  bool isOnline(DateTime now) => now.difference(lastSeenAt) < onlineWindow;

  /// Avatar on the server of [config], `null` if the user has none
  String? avatarUrl(AppConfig config) {
    final hash = avatarHash;
    if (hash == null) return null;

    return '${config.restBaseUrl}/avatars/$id?v=${Uri.encodeQueryComponent(hash)}';
  }

  @override
  List<Object?> get props => [id, name, avatarHash, provider, lastSeenAt];
}
