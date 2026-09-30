enum MatchEventType {
  substitution,
  goalFor,
  goalAgainst,
  halftime,
  secondHalf,
}

class MatchEvent {
  MatchEvent({
    required this.type,
    required this.matchSecond,
    required this.description,
    this.playerOutId,
    this.playerInId,
    this.playerId,
    this.playerOutIds = const [],
    this.playerInIds = const [],
    this.previousMatchSecond,
  });

  final MatchEventType type;
  final int matchSecond;
  final String description;
  final String? playerOutId;
  final String? playerInId;
  final String? playerId;
  final List<String> playerOutIds;
  final List<String> playerInIds;
  final int? previousMatchSecond;

  List<String> get allPlayerOutIds =>
      playerOutIds.isNotEmpty
          ? playerOutIds
          : (playerOutId == null ? const [] : [playerOutId!]);

  List<String> get allPlayerInIds =>
      playerInIds.isNotEmpty
          ? playerInIds
          : (playerInId == null ? const [] : [playerInId!]);

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'matchSecond': matchSecond,
        'description': description,
        'playerOutId': playerOutId,
        'playerInId': playerInId,
        'playerId': playerId,
        'playerOutIds': playerOutIds,
        'playerInIds': playerInIds,
        'previousMatchSecond': previousMatchSecond,
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
      playerOutIds: (json['playerOutIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      playerInIds: (json['playerInIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      previousMatchSecond: json['previousMatchSecond'] as int?,
    );
  }
}
