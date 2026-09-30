import 'package:flutter/material.dart';

import '../services/club_badge_catalog.dart';
import '../services/season_storage_service.dart';

class SeasonScreen extends StatefulWidget {
  const SeasonScreen({super.key});

  @override
  State<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends State<SeasonScreen> {
  final SeasonStorageService _storage = SeasonStorageService();

  bool _loading = true;
  List<SeasonMatchRecord> _matches = const [];
  List<SeasonPlayerTotals> _players = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final matches = await _storage.loadMatches();
    final players = await _storage.loadPlayerTotals();
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _players = players;
      _loading = false;
    });
  }

  String _minutes(int seconds) => '${seconds ~/ 60}′';

  @override
  Widget build(BuildContext context) {
    final totalSeconds = _players.fold<int>(
      0,
      (sum, player) => sum + player.playedSeconds,
    );
    final totalGoals = _matches.fold<int>(
      0,
      (sum, match) => sum + match.goalsFor,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporada'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.sports_soccer,
                          label: 'Partidos',
                          value: '${_matches.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.timer_outlined,
                          label: 'Minutos',
                          value: _minutes(totalSeconds),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.sports_score,
                          label: 'Goles',
                          value: '$totalGoals',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Minutos por jugador',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_players.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text(
                          'Todavía no hay partidos finalizados en la temporada.',
                        ),
                      ),
                    )
                  else
                    ..._players.map(
                      (player) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${player.number}'),
                          ),
                          title: Text(player.name),
                          subtitle: Text(
                            '${player.appearances} partidos · '
                            '${player.starts} titularidades · '
                            '${player.substituteAppearances} suplencias · '
                            '${player.goals} goles',
                          ),
                          trailing: Text(
                            _minutes(player.playedSeconds),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text(
                    'Partidos',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ..._matches.reversed.map(
                    (match) => Card(
                      child: ListTile(
                        leading: _ClubBadge(teamName: match.opponent),
                        title: Text(
                          '${match.team} ${match.goalsFor} - '
                          '${match.goalsAgainst} ${match.opponent}',
                        ),
                        subtitle: Text('Jornada ${match.round}'),
                        trailing: Text(_minutes(match.matchSeconds)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ClubBadge extends StatelessWidget {
  const _ClubBadge({required this.teamName});

  final String teamName;

  @override
  Widget build(BuildContext context) {
    final bytes = ClubBadgeCatalog.bytesFor(teamName);
    if (bytes == null) {
      return CircleAvatar(
        child: Text(
          teamName.isEmpty ? '?' : teamName.characters.first,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: Image.memory(
        bytes,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
