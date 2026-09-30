import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player.dart';

class SeasonPlayerRecord {
  const SeasonPlayerRecord({
    required this.id,
    required this.number,
    required this.name,
    required this.playedSeconds,
    required this.goals,
    required this.started,
  });

  final String id;
  final int number;
  final String name;
  final int playedSeconds;
  final int goals;
  final bool started;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'name': name,
        'playedSeconds': playedSeconds,
        'goals': goals,
        'started': started,
      };

  factory SeasonPlayerRecord.fromJson(Map<String, dynamic> json) {
    return SeasonPlayerRecord(
      id: json['id'] as String? ?? '',
      number: json['number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      playedSeconds: json['playedSeconds'] as int? ?? 0,
      goals: json['goals'] as int? ?? 0,
      started: json['started'] as bool? ?? false,
    );
  }

  factory SeasonPlayerRecord.fromPlayer(Player player) {
    return SeasonPlayerRecord(
      id: player.id,
      number: player.number,
      name: player.name,
      playedSeconds: player.playedSeconds,
      goals: player.goals,
      started: player.started,
    );
  }
}

class SeasonMatchRecord {
  const SeasonMatchRecord({
    required this.id,
    required this.team,
    required this.opponent,
    required this.round,
    required this.matchSeconds,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.finishedAtIso,
    required this.players,
  });

  final String id;
  final String team;
  final String opponent;
  final String round;
  final int matchSeconds;
  final int goalsFor;
  final int goalsAgainst;
  final String finishedAtIso;
  final List<SeasonPlayerRecord> players;

  Map<String, dynamic> toJson() => {
        'id': id,
        'team': team,
        'opponent': opponent,
        'round': round,
        'matchSeconds': matchSeconds,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
        'finishedAtIso': finishedAtIso,
        'players': players.map((player) => player.toJson()).toList(),
      };

  factory SeasonMatchRecord.fromJson(Map<String, dynamic> json) {
    return SeasonMatchRecord(
      id: json['id'] as String? ?? '',
      team: json['team'] as String? ?? '',
      opponent: json['opponent'] as String? ?? '',
      round: json['round'] as String? ?? '',
      matchSeconds: json['matchSeconds'] as int? ?? 0,
      goalsFor: json['goalsFor'] as int? ?? 0,
      goalsAgainst: json['goalsAgainst'] as int? ?? 0,
      finishedAtIso: json['finishedAtIso'] as String? ?? '',
      players: (json['players'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SeasonPlayerRecord.fromJson)
          .toList(),
    );
  }
}

class SeasonPlayerTotals {
  SeasonPlayerTotals({
    required this.id,
    required this.number,
    required this.name,
  });

  final String id;
  final int number;
  final String name;
  int playedSeconds = 0;
  int goals = 0;
  int appearances = 0;
  int starts = 0;

  int get substituteAppearances => (appearances - starts).clamp(0, 999);
}

class SeasonStorageService {
  static const _seasonKey = 'season_matches_v1';

  Future<List<SeasonMatchRecord>> loadMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_seasonKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SeasonMatchRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFinishedMatch({
    required String team,
    required String opponent,
    required String round,
    required int matchSeconds,
    required int goalsFor,
    required int goalsAgainst,
    required List<Player> players,
  }) async {
    final matches = await loadMatches();
    final id =
        '${team.trim().toLowerCase()}|${opponent.trim().toLowerCase()}|${round.trim()}';
    final record = SeasonMatchRecord(
      id: id,
      team: team,
      opponent: opponent,
      round: round,
      matchSeconds: matchSeconds,
      goalsFor: goalsFor,
      goalsAgainst: goalsAgainst,
      finishedAtIso: DateTime.now().toIso8601String(),
      players: players.map(SeasonPlayerRecord.fromPlayer).toList(),
    );

    final existingIndex = matches.indexWhere((match) => match.id == id);
    if (existingIndex >= 0) {
      matches[existingIndex] = record;
    } else {
      matches.add(record);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _seasonKey,
      jsonEncode(matches.map((match) => match.toJson()).toList()),
    );
  }

  Future<List<SeasonPlayerTotals>> loadPlayerTotals() async {
    final matches = await loadMatches();
    final totals = <String, SeasonPlayerTotals>{};

    for (final match in matches) {
      for (final player in match.players) {
        final key = player.id.isNotEmpty ? player.id : player.name.toLowerCase();
        final total = totals.putIfAbsent(
          key,
          () => SeasonPlayerTotals(
            id: player.id,
            number: player.number,
            name: player.name,
          ),
        );

        total.playedSeconds += player.playedSeconds;
        total.goals += player.goals;
        if (player.playedSeconds > 0) total.appearances++;
        if (player.started) total.starts++;
      }
    }

    final result = totals.values.toList()
      ..sort((a, b) => b.playedSeconds.compareTo(a.playedSeconds));
    return result;
  }
}
