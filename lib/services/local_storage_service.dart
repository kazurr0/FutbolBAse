import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MatchSnapshot {
  const MatchSnapshot({
    required this.matchSeconds,
    required this.homeGoals,
    required this.awayGoals,
    required this.players,
    required this.events,
  });

  final int matchSeconds;
  final int homeGoals;
  final int awayGoals;
  final List<Map<String, dynamic>> players;
  final List<Map<String, dynamic>> events;

  Map<String, dynamic> toJson() => {
        'matchSeconds': matchSeconds,
        'homeGoals': homeGoals,
        'awayGoals': awayGoals,
        'players': players,
        'events': events,
      };

  factory MatchSnapshot.fromJson(Map<String, dynamic> json) {
    return MatchSnapshot(
      matchSeconds: json['matchSeconds'] as int? ?? 0,
      homeGoals: json['homeGoals'] as int? ?? 0,
      awayGoals: json['awayGoals'] as int? ?? 0,
      players: (json['players'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      events: (json['events'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }
}

class LocalStorageService {
  static const _matchKey = 'active_match_snapshot_v1';

  Future<void> saveMatch(MatchSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_matchKey, jsonEncode(snapshot.toJson()));
  }

  Future<MatchSnapshot?> loadMatch() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_matchKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return MatchSnapshot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearMatch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_matchKey);
  }
}
