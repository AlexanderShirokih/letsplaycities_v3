import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';

/// How another user relates to the signed-in one: the `friendship` field of
/// `GET /v1/users/{id}`
enum Friendship {
  none,
  friends,

  /// The other user sent a request to the signed-in one
  incoming,

  /// The signed-in user sent a request to the other one
  outgoing;

  /// Returns the status the protocol names [wire]. Throws [FormatException]
  /// for an unknown name.
  static Friendship fromWire(String wire) => values.firstWhere(
    (value) => value.name == wire,
    orElse: () => throw FormatException('Unknown friendship "$wire"'),
  );
}

/// Block between the signed-in user and another one: the `blocked` field of
/// `GET /v1/users/{id}`
enum Blocked {
  none,

  /// The signed-in user blocked the other one
  byMe,

  /// The other user blocked the signed-in one
  me,
  both;

  /// Returns the status the protocol names [wire]. Throws [FormatException]
  /// for an unknown name.
  static Blocked fromWire(String wire) => values.firstWhere(
    (value) => value.name == wire,
    orElse: () => throw FormatException('Unknown blocked status "$wire"'),
  );

  /// `true` when the signed-in user blocked the other one
  bool get isBlockedByMe => this == byMe || this == both;

  /// `true` when the other user blocked the signed-in one
  bool get isBlockingMe => this == me || this == both;
}

/// A user with the way they relate to the signed-in user: the answer of
/// `GET /v1/users/{id}`
class UserProfile extends Equatable {
  final LpsUser user;
  final Friendship friendship;
  final Blocked blocked;

  const UserProfile({
    required this.user,
    required this.friendship,
    required this.blocked,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    user: LpsUser.fromJson(json),
    friendship: Friendship.fromWire(json['friendship'] as String),
    blocked: Blocked.fromWire(json['blocked'] as String),
  );

  /// The invitation and the friend request are impossible while either user
  /// blocks the other
  bool get canInvite => blocked == Blocked.none;

  @override
  List<Object?> get props => [user, friendship, blocked];
}

/// Status of an entry of `GET /v1/friends`
enum FriendStatus {
  friends,
  incoming,
  outgoing;

  /// Returns the status the protocol names [wire]. Throws [FormatException]
  /// for an unknown name.
  static FriendStatus fromWire(String wire) => values.firstWhere(
    (value) => value.name == wire,
    orElse: () => throw FormatException('Unknown friend status "$wire"'),
  );
}

/// An entry of the friend list: a friend or a pending request
class FriendEntry extends Equatable {
  final LpsUser user;
  final FriendStatus status;

  const FriendEntry(this.user, this.status);

  factory FriendEntry.fromJson(Map<String, dynamic> json) => FriendEntry(
    LpsUser.fromJson(json['user'] as Map<String, dynamic>),
    FriendStatus.fromWire(json['status'] as String),
  );

  @override
  List<Object?> get props => [user, status];
}

/// A finished game of the signed-in user
class HistoryGame extends Equatable {
  final int id;
  final LpsUser opponent;
  final bool isFriend;
  final DateTime startedAt;
  final int durationSec;

  /// Count of the words played by both users
  final int words;

  const HistoryGame({
    required this.id,
    required this.opponent,
    required this.isFriend,
    required this.startedAt,
    required this.durationSec,
    required this.words,
  });

  factory HistoryGame.fromJson(Map<String, dynamic> json) => HistoryGame(
    id: json['id'] as int,
    opponent: LpsUser.fromJson(json['opponent'] as Map<String, dynamic>),
    isFriend: json['isFriend'] as bool,
    startedAt: DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int),
    durationSec: json['durationSec'] as int,
    words: json['words'] as int,
  );

  @override
  List<Object?> get props => [
    id,
    opponent,
    isFriend,
    startedAt,
    durationSec,
    words,
  ];
}

/// A page of the history, from the newest game to the oldest
class HistoryPage extends Equatable {
  final List<HistoryGame> games;

  /// Cursor of the next page for the `before` parameter, `null` on the last
  /// page
  final int? next;

  const HistoryPage(this.games, this.next);

  factory HistoryPage.fromJson(Map<String, dynamic> json) => HistoryPage([
    for (final game in json['games'] as List<dynamic>)
      HistoryGame.fromJson(game as Map<String, dynamic>),
  ], json['next'] as int?);

  @override
  List<Object?> get props => [games, next];
}
