import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/club_badge_catalog.dart';
import '../services/lineup_import_service.dart';
import '../services/local_storage_service.dart';
import '../services/season_storage_service.dart';
import 'live_match_screen.dart';
import 'season_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocalStorageService _storage = LocalStorageService();
  final SeasonStorageService _seasonStorage = SeasonStorageService();
  final LineupImportService _lineupImportService = LineupImportService();

  MatchSnapshot? _savedMatch;
  List<Player>? _importedPlayers;
  String? _importStatus;
  bool _importing = false;
  int _seasonMatches = 0;
  int _seasonGoals = 0;
  int _seasonPlayerMinutes = 0;

  final _teamController = TextEditingController(text: 'S.D. Ponferradina');
  final _rivalController = TextEditingController(text: 'C.D. Ponferrada City');
  final _roundController = TextEditingController(text: '24');
  final _minutesController = TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    final snapshot = await _storage.loadMatch();
    final matches = await _seasonStorage.loadMatches();
    final totals = await _seasonStorage.loadPlayerTotals();
    if (!mounted) return;

    setState(() {
      _savedMatch = snapshot;
      _seasonMatches = matches.length;
      _seasonGoals = matches.fold(0, (sum, match) => sum + match.goalsFor);
      _seasonPlayerMinutes =
          totals.fold(0, (sum, player) => sum + player.playedSeconds) ~/ 60;
    });
  }

  void _openSeason() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SeasonScreen()))
        .then((_) => _refreshDashboard());
  }

  void _continueMatch() {
    final match = _savedMatch;
    if (match == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => LiveMatchScreen(
              homeTeam: match.homeTeam,
              awayTeam: match.awayTeam,
              round: match.round,
              plannedMinutes: match.plannedMinutes,
            ),
          ),
        )
        .then((_) => _refreshDashboard());
  }

  Future<void> _importPdf() async {
    setState(() {
      _importing = true;
      _importStatus = null;
    });

    try {
      final result = await _lineupImportService.pickAndImportPdf();
      if (result == null || !mounted) return;

      setState(() {
        _teamController.text = result.ourTeam;
        _rivalController.text = result.opponent;
        if (result.round.isNotEmpty) {
          _roundController.text = result.round;
        }
        _importedPlayers = result.players;
        _importStatus =
            '${result.players.length} jugadores cargados · Jornada ${result.round}';
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() => _importStatus = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _importStatus =
            'No se pudo leer el PDF. Prueba con otro documento.',
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  void dispose() {
    _teamController.dispose();
    _rivalController.dispose();
    _roundController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _startMatch() async {
    if (!_formKey.currentState!.validate()) return;

    await _storage.clearMatch();
    if (!mounted) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => LiveMatchScreen(
              homeTeam: _teamController.text.trim(),
              awayTeam: _rivalController.text.trim(),
              round: _roundController.text.trim(),
              plannedMinutes: int.parse(_minutesController.text.trim()),
              initialPlayers: _importedPlayers,
            ),
          ),
        )
        .then((_) => _refreshDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final teamName = _teamController.text.trim();
    final badge = ClubBadgeCatalog.imageProviderFor(teamName);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FutbolBAse',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Temporada',
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: _openSeason,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _TeamHero(teamName: teamName, badge: badge),
              const SizedBox(height: 12),
              _PrimaryActions(
                importing: _importing,
                hasSavedMatch: _savedMatch != null,
                onImport: _importPdf,
                onContinue: _savedMatch == null ? null : _continueMatch,
                onSeason: _openSeason,
              ),
              if (_savedMatch != null) ...[
                const SizedBox(height: 12),
                _SavedMatchCard(
                  match: _savedMatch!,
                  onContinue: _continueMatch,
                ),
              ],
              const SizedBox(height: 12),
              _SeasonSummary(
                matches: _seasonMatches,
                minutes: _seasonPlayerMinutes,
                goals: _seasonGoals,
                onTap: _openSeason,
              ),
              const SizedBox(height: 16),
              Text(
                'Preparar partido',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              if (_importStatus != null)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(_importStatus!),
                    subtitle: _importedPlayers == null
                        ? null
                        : Text(
                            '${_importedPlayers!.where((p) => p.onField).length} titulares · '
                            '${_importedPlayers!.where((p) => !p.onField).length} suplentes',
                          ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _teamController,
                                decoration: const InputDecoration(
                                  labelText: 'Nuestro equipo',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.shield_outlined),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Introduce el equipo'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _rivalController,
                                decoration: const InputDecoration(
                                  labelText: 'Rival',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.sports_soccer),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Introduce el rival'
                                        : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _roundController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Jornada',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Obligatorio'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _minutesController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Duración',
                                  suffixText: 'min',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.timer_outlined),
                                ),
                                validator: (value) {
                                  final minutes = int.tryParse(value ?? '');
                                  return minutes == null || minutes <= 0
                                      ? 'Minutos válidos'
                                      : null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _importing ? null : _importPdf,
                                icon: _importing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 13),
                                  child: Text('Importar acta'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _startMatch,
                                icon: const Icon(Icons.play_arrow),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 13),
                                  child: Text('Empezar partido'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_importedPlayers != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.groups_rounded),
                    title: const Text(
                      'Alineación detectada',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${_importedPlayers!.where((p) => p.onField).length} titulares · '
                      '${_importedPlayers!.where((p) => !p.onField).length} suplentes',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _importedPlayers!
                              .map(
                                (player) => Chip(
                                  avatar: CircleAvatar(
                                    child: Text('${player.number}'),
                                  ),
                                  label: Text(player.name.split(' ').first),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero({required this.teamName, required this.badge});

  final String teamName;
  final ImageProvider<Object>? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              height: 74,
              child: badge == null
                  ? CircleAvatar(
                      child: Text(
                        teamName.isEmpty ? '?' : teamName.characters.first,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : Image(
                      image: badge!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName.isEmpty ? 'Mi equipo' : teamName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Control de minutos y temporada'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({
    required this.importing,
    required this.hasSavedMatch,
    required this.onImport,
    required this.onContinue,
    required this.onSeason,
  });

  final bool importing;
  final bool hasSavedMatch;
  final VoidCallback onImport;
  final VoidCallback? onContinue;
  final VoidCallback onSeason;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.picture_as_pdf,
          label: 'Importar',
          onTap: importing ? null : onImport,
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.play_circle_fill,
          label: hasSavedMatch ? 'Continuar' : 'Sin partido',
          onTap: onContinue,
        ),
        const SizedBox(width: 8),
        _QuickAction(
          icon: Icons.leaderboard_rounded,
          label: 'Temporada',
          onTap: onSeason,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, size: 29),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedMatchCard extends StatelessWidget {
  const _SavedMatchCard({required this.match, required this.onContinue});

  final MatchSnapshot match;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.play_arrow)),
        title: const Text(
          'Partido en curso',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${match.homeTeam} vs ${match.awayTeam}\n'
          'Jornada ${match.round} · ${_time(match.matchSeconds)}',
        ),
        isThreeLine: true,
        trailing: FilledButton(
          onPressed: onContinue,
          child: const Text('Reanudar'),
        ),
      ),
    );
  }

  static String _time(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _SeasonSummary extends StatelessWidget {
  const _SeasonSummary({
    required this.matches,
    required this.minutes,
    required this.goals,
    required this.onTap,
  });

  final int matches;
  final int minutes;
  final int goals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Resumen de temporada',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: onTap,
                    child: const Text('Ver todo'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      value: '$matches',
                      label: 'Partidos',
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      value: '$minutes′',
                      label: 'Minutos',
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      value: '$goals',
                      label: 'Goles',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
