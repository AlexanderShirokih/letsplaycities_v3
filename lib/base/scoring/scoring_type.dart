/// Defines game score calculation and winner checking strategy
enum ScoringType {
  /// In this mode wins user that has bigger score
  byScore,

  /// In this mode wins user that has bigger score.
  /// In this case more score will got user that sends word faster
  byTime,

  /// In this mode wins user that writes last accepted word
  lastMove,
}
