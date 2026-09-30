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

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'matchSecond': matchSecond,
        'description': description,
        'playerOutId': playerOutId,
        'playerInId': playerInId,
        'playerId': playerId,
      };

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? MatchEventType.substitution.name;
    final type = MatchEventType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => MatchEventType.substitution,
    );

    return MatchEvent(
      type: type,
      matchSecond: json['matchSecond'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      playerOutId: json['playerOutId'] as String?,
      playerInId: json['playerInId'] as String?,
      playerId: json['playerId'] as String?,
    );
  }
}
