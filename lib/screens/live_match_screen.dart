import 'dart:async';
import 'package:flutter/material.dart';

import '../models/match_event.dart';
import '../models/player.dart';
import '../services/club_badge_catalog.dart';
import '../services/local_storage_service.dart';
import '../services/season_storage_service.dart';
import 'match_summary_screen.dart';

class LiveMatchScreen extends StatefulWidget {
  const LiveMatchScreen({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.round,
    required this.plannedMinutes,
    this.initialPlayers,
  });

  final String homeTeam;
  final String awayTeam;
  final String round;
  final int plannedMinutes;
  final List<Player>? initialPlayers;

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  final LocalStorageService _storage = LocalStorageService();
  final SeasonStorageService _seasonStorage = SeasonStorageService();

  late final List<Player> _players;

  final List<MatchEvent> _events = [];

  Timer? _timer;
  bool _running = false;
  int _matchSeconds = 0;
  int _homeGoals = 0;
  int _awayGoals = 0;
  bool _isHalftime = false;
  bool _secondHalf = false;
  String? _notice;

  List<Player> get _onField =>
      _players.where((player) => player.onField).toList();

  List<Player> get _bench =>
      _players.where((player) => !player.onField).toList();

  @override
  void initState() {
    super.initState();
    _players = widget.initialPlayers
            ?.map(
              (player) => Player(
                id: player.id,
                number: player.number,
                name: player.name,
                onField: player.onField,
                started: player.started,
                playedSeconds: player.playedSeconds,
                firstHalfSeconds: player.firstHalfSeconds,
                secondHalfSeconds: player.secondHalfSeconds,
                goals: player.goals,
              ),
            )
            .toList() ??
        [
          Player(id: '13', number: 13, name: 'Leo García Prada', onField: true),
          Player(id: '3', number: 3, name: 'Hugo Aira Almeida', onField: true),
          Player(id: '5', number: 5, name: 'Leo Calzado Martínez', onField: true),
          Player(id: '6', number: 6, name: 'Luka Calzado Martínez', onField: true),
          Player(id: '10', number: 10, name: 'Iago Álvarez Gómez', onField: true),
          Player(id: '11', number: 11, name: 'David Luca Gomes Valerio', onField: true),
          Player(id: '12', number: 12, name: 'Héctor Romanos Poncelas', onField: true),
          Player(id: '2', number: 2, name: 'Martín Fernández Sánchez', onField: false),
          Player(id: '4', number: 4, name: 'Alejandro Prieto Molinete', onField: false),
          Player(id: '7', number: 7, name: 'Mateo Otero Álvarez', onField: false),
          Player(id: '8', number: 8, name: 'Nel Merayo Fernández', onField: false),
          Player(id: '9', number: 9, name: 'Mateo Vuelta Imbachí', onField: false),
        ];
    _restoreMatch();
  }

  Future<void> _restoreMatch() async {
    final snapshot = await _storage.loadMatch();
    if (snapshot == null || !mounted) return;
    final sameMatch = snapshot.homeTeam == widget.homeTeam &&
        snapshot.awayTeam == widget.awayTeam &&
        snapshot.round == widget.round;
    if (!sameMatch) return;

    setState(() {
      if (snapshot.players.isNotEmpty) {
        _players
          ..clear()
          ..addAll(snapshot.players.map(Player.fromJson));
      }
      _events
        ..clear()
        ..addAll(snapshot.events.map(MatchEvent.fromJson));
      _matchSeconds = snapshot.matchSeconds;
      _homeGoals = snapshot.homeGoals;
      _awayGoals = snapshot.awayGoals;
      _isHalftime = snapshot.isHalftime;
      _secondHalf = snapshot.secondHalf;
      _running = false;
    });
  }

  Future<void> _persistMatch() async {
    await _storage.saveMatch(
      MatchSnapshot(
        homeTeam: widget.homeTeam,
        awayTeam: widget.awayTeam,
        round: widget.round,
        plannedMinutes: widget.plannedMinutes,
        matchSeconds: _matchSeconds,
        homeGoals: _homeGoals,
        awayGoals: _awayGoals,
        players: _players.map((player) => player.toJson()).toList(),
        events: _events.map((event) => event.toJson()).toList(),
        isHalftime: _isHalftime,
        secondHalf: _secondHalf,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running || !mounted) return;
      setState(() {
        _matchSeconds++;
        for (final player in _players) {
          if (!player.onField) continue;
          player.playedSeconds++;
          if (_secondHalf) {
            player.secondHalfSeconds++;
          } else {
            player.firstHalfSeconds++;
          }
        }
      });
      if (_matchSeconds % 5 == 0) {
        _persistMatch();
      }
    });
  }

  void _toggleTimer() {
    if (_isHalftime) return;
    setState(() => _running = !_running);
    _persistMatch();
    if (_running) _ensureTimer();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _registerSubstitution() async {
    if (_onField.isEmpty || _bench.isEmpty) return;

    final selectedOutIds = <String>{};
    final selectedInIds = <String>{};

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final balanced = selectedOutIds.isNotEmpty &&
                selectedOutIds.length == selectedInIds.length;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cambios',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        balanced
                            ? '${selectedOutIds.length} cambio(s) preparados'
                            : 'Selecciona el mismo número de salidas y entradas',
                        style: TextStyle(
                          color: balanced
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Salen del campo',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _onField.map((player) {
                          final selected = selectedOutIds.contains(player.id);
                          return FilterChip(
                            avatar: CircleAvatar(
                              child: Text('${player.number}'),
                            ),
                            label: Text(player.name.split(' ').first),
                            selected: selected,
                            onSelected: (value) {
                              setSheetState(() {
                                if (value) {
                                  selectedOutIds.add(player.id);
                                } else {
                                  selectedOutIds.remove(player.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Entran al campo',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _bench.map((player) {
                          final selected = selectedInIds.contains(player.id);
                          return FilterChip(
                            avatar: CircleAvatar(
                              child: Text('${player.number}'),
                            ),
                            label: Text(player.name.split(' ').first),
                            selected: selected,
                            onSelected: (value) {
                              setSheetState(() {
                                if (value) {
                                  selectedInIds.add(player.id);
                                } else {
                                  selectedInIds.remove(player.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: balanced
                              ? () => Navigator.pop(context, true)
                              : null,
                          icon: const Icon(Icons.swap_horiz),
                          label: Text(
                            selectedOutIds.length <= 1
                                ? 'Confirmar cambio'
                                : 'Confirmar ${selectedOutIds.length} cambios',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final playersOut = _players
        .where((player) => selectedOutIds.contains(player.id))
        .toList();
    final playersIn = _players
        .where((player) => selectedInIds.contains(player.id))
        .toList();

    if (playersOut.isEmpty || playersOut.length != playersIn.length) return;

    setState(() {
      for (final player in playersOut) {
        player.onField = false;
      }
      for (final player in playersIn) {
        player.onField = true;
      }

      final exits = playersOut
          .map((player) => '${player.number} ${player.name}')
          .join(', ');
      final entries = playersIn
          .map((player) => '${player.number} ${player.name}')
          .join(', ');

      _events.insert(
        0,
        MatchEvent(
          type: MatchEventType.substitution,
          matchSecond: _matchSeconds,
          description: 'Salen: $exits · Entran: $entries',
          playerOutIds: playersOut.map((player) => player.id).toList(),
          playerInIds: playersIn.map((player) => player.id).toList(),
        ),
      );
    });

    _persistMatch();
    _showNotice(
      playersOut.length == 1
          ? 'Cambio registrado'
          : '${playersOut.length} cambios registrados',
    );
  }

  Future<void> _registerGoal() async {
    bool ourGoal = true;
    Player? scorer;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Registrar gol',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.sports_soccer),
                          label: Text('Nuestro'),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.sports_soccer),
                          label: Text('Rival'),
                        ),
                      ],
                      selected: {ourGoal},
                      onSelectionChanged: (value) {
                        setSheetState(() {
                          ourGoal = value.first;
                          if (!ourGoal) scorer = null;
                        });
                      },
                    ),
                    if (ourGoal) ...[
                      const SizedBox(height: 18),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '¿Quién ha marcado?',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._onField.map(
                        (player) => RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          value: player.id,
                          groupValue: scorer?.id,
                          title: Text('${player.number} · ${player.name}'),
                          onChanged: (_) {
                            setSheetState(() => scorer = player);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: !ourGoal || scorer != null
                            ? () => Navigator.pop(context, true)
                            : null,
                        child: const Text('Guardar gol'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      if (ourGoal) {
        _homeGoals++;
        scorer!.goals++;
        _events.insert(
          0,
          MatchEvent(
            type: MatchEventType.goalFor,
            matchSecond: _matchSeconds,
            description: 'Gol de ${scorer!.number} ${scorer!.name}',
            playerId: scorer!.id,
          ),
        );
      } else {
        _awayGoals++;
        _events.insert(
          0,
          MatchEvent(
            type: MatchEventType.goalAgainst,
            matchSecond: _matchSeconds,
            description: 'Gol del rival',
          ),
        );
      }
    });

    _persistMatch();
    _showNotice('Gol registrado');
  }

  void _showNotice(String message) {
    setState(() => _notice = message);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted || _notice != message) return;
      setState(() => _notice = null);
    });
  }

  void _toggleHalftime() {
    if (!_secondHalf && !_isHalftime) {
      setState(() {
        _running = false;
        _isHalftime = true;
        _events.insert(
          0,
          MatchEvent(
            type: MatchEventType.halftime,
            matchSecond: _matchSeconds,
            description: 'Descanso',
          ),
        );
      });
      _persistMatch();
      _showNotice('Descanso registrado');
      return;
    }

    if (_isHalftime) {
      final firstHalfEndSecond = _matchSeconds;
      setState(() {
        _matchSeconds = 25 * 60;
        _isHalftime = false;
        _secondHalf = true;
        _running = true;
        _events.insert(
          0,
          MatchEvent(
            type: MatchEventType.secondHalf,
            matchSecond: _matchSeconds,
            previousMatchSecond: firstHalfEndSecond,
            description: 'Comienza la 2ª parte en 25:00',
          ),
        );
      });
      _ensureTimer();
      _persistMatch();
      _showNotice('2ª parte iniciada en 25:00');
      return;
    }

    _finishMatch();
  }

  void _undoLastEvent() {
    if (_events.isEmpty) return;

    setState(() {
      final event = _events.removeAt(0);

      switch (event.type) {
        case MatchEventType.substitution:
          for (final id in event.allPlayerOutIds) {
            final matches = _players.where((p) => p.id == id);
            if (matches.isNotEmpty) matches.first.onField = true;
          }
          for (final id in event.allPlayerInIds) {
            final matches = _players.where((p) => p.id == id);
            if (matches.isNotEmpty) matches.first.onField = false;
          }
          break;
        case MatchEventType.goalFor:
          _homeGoals = (_homeGoals - 1).clamp(0, 999).toInt();
          if (event.playerId != null) {
            final player = _players.firstWhere((p) => p.id == event.playerId);
            player.goals = (player.goals - 1).clamp(0, 999).toInt();
          }
          break;
        case MatchEventType.goalAgainst:
          _awayGoals = (_awayGoals - 1).clamp(0, 999).toInt();
          break;
        case MatchEventType.halftime:
          _isHalftime = false;
          _secondHalf = false;
          break;
        case MatchEventType.secondHalf:
          _running = false;
          _isHalftime = true;
          _secondHalf = false;
          _matchSeconds = event.previousMatchSecond ?? _matchSeconds;
          break;
      }
    });
    _persistMatch();
  }

  void _showHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Historial del partido',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_events.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _undoLastEvent();
                          },
                          icon: const Icon(Icons.undo),
                          label: const Text('Deshacer último'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _events.isEmpty
                      ? const Center(
                          child: Text('Todavía no hay eventos registrados.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                          itemCount: _events.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final event = _events[index];
                            return ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor:
                                  Theme.of(context).colorScheme.surfaceContainer,
                              leading: Icon(
                                event.type == MatchEventType.substitution
                                    ? Icons.swap_horiz
                                    : Icons.sports_soccer,
                              ),
                              title: Text(event.description),
                              trailing: Text(_formatTime(event.matchSecond)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _finishMatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar partido'),
        content: const Text(
          'Se cerrará el cronómetro y se mostrará el resumen de minutos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _running = false);
    await _persistMatch();
    await _seasonStorage.saveFinishedMatch(
      team: widget.homeTeam,
      opponent: widget.awayTeam,
      round: widget.round,
      matchSeconds: _matchSeconds,
      goalsFor: _homeGoals,
      goalsAgainst: _awayGoals,
      players: _players,
    );
    await _storage.clearMatch();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MatchSummaryScreen(
          homeTeam: widget.homeTeam,
          awayTeam: widget.awayTeam,
          homeGoals: _homeGoals,
          awayGoals: _awayGoals,
          matchSeconds: _matchSeconds,
          players: _players,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plannedSeconds =
        widget.plannedMinutes > 0 ? widget.plannedMinutes * 60 : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partido en directo'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Historial',
            onPressed: _showHistory,
            icon: Badge(
              isLabelVisible: _events.isNotEmpty,
              label: Text('${_events.length}'),
              child: const Icon(Icons.history),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ScoreHeader(
              homeTeam: widget.homeTeam,
              awayTeam: widget.awayTeam,
              round: widget.round,
              homeGoals: _homeGoals,
              awayGoals: _awayGoals,
              time: _formatTime(_matchSeconds),
              running: _running,
              phaseText: _isHalftime
                  ? 'Descanso'
                  : (_secondHalf ? '2ª parte' : '1ª parte'),
              onToggle: _toggleTimer,
            ),
            if (_notice != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Material(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _notice!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onInverseSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                children: [
                  _SectionTitle(title: 'En juego', count: _onField.length),
                  ..._onField.map(
                    (player) => _PlayerRow(
                      player: player,
                      time: _formatTime(player.playedSeconds),
                      plannedSeconds: plannedSeconds,
                      firstHalfSeconds: player.firstHalfSeconds,
                      secondHalfSeconds: player.secondHalfSeconds,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionTitle(title: 'Banquillo', count: _bench.length),
                  ..._bench.map(
                    (player) => _PlayerRow(
                      player: player,
                      time: _formatTime(player.playedSeconds),
                      plannedSeconds: plannedSeconds,
                      firstHalfSeconds: player.firstHalfSeconds,
                      secondHalfSeconds: player.secondHalfSeconds,
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(10, 4, 10, 8),
        child: _MatchActionBar(
          onGoal: _registerGoal,
          onSubstitution: _registerSubstitution,
          onPhase: _toggleHalftime,
          onUndo: _events.isEmpty ? null : _undoLastEvent,
          phaseIcon: _isHalftime
              ? Icons.play_arrow
              : (_secondHalf ? Icons.flag : Icons.free_breakfast),
          phaseLabel: _isHalftime
              ? '2ª parte'
              : (_secondHalf ? 'Final' : 'Descanso'),
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({
    required this.homeTeam,
    required this.awayTeam,
    required this.round,
    required this.homeGoals,
    required this.awayGoals,
    required this.time,
    required this.running,
    required this.phaseText,
    required this.onToggle,
  });

  final String homeTeam;
  final String awayTeam;
  final String round;
  final int homeGoals;
  final int awayGoals;
  final String time;
  final bool running;
  final String phaseText;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Text('Jornada $round'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _TeamBadgeName(
                    teamName: homeTeam,
                    alignEnd: false,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _TeamBadgeName(
                    teamName: awayTeam,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            Text(
              '$homeGoals  -  $awayGoals',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              phaseText,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  running ? Icons.circle : Icons.pause_circle,
                  size: 10,
                  color: running ? Colors.red : null,
                ),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: onToggle,
                  icon: Icon(running ? Icons.pause : Icons.play_arrow),
                  label: Text(running ? 'Pausar' : 'Iniciar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchActionBar extends StatelessWidget {
  const _MatchActionBar({
    required this.onGoal,
    required this.onSubstitution,
    required this.onPhase,
    required this.onUndo,
    required this.phaseIcon,
    required this.phaseLabel,
  });

  final VoidCallback onGoal;
  final VoidCallback onSubstitution;
  final VoidCallback onPhase;
  final VoidCallback? onUndo;
  final IconData phaseIcon;
  final String phaseLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            _MatchAction(
              icon: Icons.sports_soccer,
              label: 'Gol',
              onPressed: onGoal,
            ),
            _MatchAction(
              icon: Icons.swap_horiz,
              label: 'Cambio',
              onPressed: onSubstitution,
            ),
            _MatchAction(
              icon: phaseIcon,
              label: phaseLabel,
              onPressed: onPhase,
            ),
            _MatchAction(
              icon: Icons.undo,
              label: 'Deshacer',
              onPressed: onUndo,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchAction extends StatelessWidget {
  const _MatchAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 25),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamBadgeName extends StatelessWidget {
  const _TeamBadgeName({
    required this.teamName,
    required this.alignEnd,
  });

  final String teamName;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final badge = ClubBadgeCatalog.bytesFor(teamName);

    final image = badge == null
        ? CircleAvatar(
            radius: 20,
            child: Text(
              teamName.isEmpty ? '?' : teamName.characters.first,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          )
        : SizedBox(
            width: 42,
            height: 42,
            child: Image.memory(
              badge,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          );

    final name = Expanded(
      child: Text(
        teamName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: alignEnd
          ? [name, const SizedBox(width: 8), image]
          : [image, const SizedBox(width: 8), name],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Text(
            '($count)',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PlayerTimeline extends StatelessWidget {
  const _PlayerTimeline({
    required this.plannedSeconds,
    required this.firstHalfSeconds,
    required this.secondHalfSeconds,
  });

  final int plannedSeconds;
  final int firstHalfSeconds;
  final int secondHalfSeconds;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = plannedSeconds <= 0 ? 1 : plannedSeconds;
        final firstRatio = (firstHalfSeconds / total).clamp(0.0, 1.0);
        final secondRatio =
            (secondHalfSeconds / total).clamp(0.0, 1.0 - firstRatio);

        return ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 5,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                SizedBox(
                  width: constraints.maxWidth * firstRatio,
                  child: Container(color: Colors.green),
                ),
                SizedBox(
                  width: constraints.maxWidth * secondRatio,
                  child: Container(color: Colors.blue),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.time,
    required this.plannedSeconds,
    required this.firstHalfSeconds,
    required this.secondHalfSeconds,
  });

  final Player player;
  final String time;
  final int plannedSeconds;
  final int firstHalfSeconds;
  final int secondHalfSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              child: Text(
                '${player.number}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (player.goals > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text('⚽ ${player.goals}'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  _PlayerTimeline(
                    plannedSeconds: plannedSeconds,
                    firstHalfSeconds: firstHalfSeconds,
                    secondHalfSeconds: secondHalfSeconds,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              child: Text(
                time,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      );
  }
}
