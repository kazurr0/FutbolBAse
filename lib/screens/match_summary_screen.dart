import 'package:flutter/material.dart';

import '../models/player.dart';

class MatchSummaryScreen extends StatelessWidget {
  const MatchSummaryScreen({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeGoals,
    required this.awayGoals,
    required this.matchSeconds,
    required this.players,
  });

  final String homeTeam;
  final String awayTeam;
  final int homeGoals;
  final int awayGoals;
  final int matchSeconds;
  final List<Player> players;

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlayers = [...players]
      ..sort((a, b) => b.playedSeconds.compareTo(a.playedSeconds));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del partido'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    '$homeTeam  $homeGoals - $awayGoals  $awayTeam',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('Duración registrada: ${_formatTime(matchSeconds)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Minutos por jugador',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          ...sortedPlayers.map(
            (player) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${player.number}'),
                ),
                title: Text(player.name),
                subtitle: Text(player.goals > 0
                    ? 'Goles: ${player.goals}'
                    : 'Sin goles'),
                trailing: Text(
                  _formatTime(player.playedSeconds),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Volver al inicio'),
            ),
          ),
        ],
      ),
    );
  }
}
