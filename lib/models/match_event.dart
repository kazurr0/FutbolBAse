enum MatchEventType {
  substitution,
  goalFor,
  goalAgainst,
}

class MatchEvent {
  MatchEvent({
    required this.type,
    required this.matchSecond,
    required this.description,
    this.playerOutId,
    this.playerInId,
    this.playerId,
  });

  final MatchEventType type;
  final int matchSecond;
  final String description;
  final String? playerOutId;
  final String? playerInId;
  final String? playerId;
}
