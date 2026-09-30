import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../models/match_event.dart';
import '../models/player.dart';

class LiveMatchScreen extends StatefulWidget {
  const LiveMatchScreen({super.key});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  final List<Player> _players = [
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

  final List<MatchEvent> _events = [];

  Timer? _timer;
  bool _running = false;
  int _matchSeconds = 0;
  int _homeGoals = 0;
  int _awayGoals = 0;

  List<Player> get _onField =>
      _players.where((player) => player.onField).toList();

  List<Player> get _bench =>
      _players.where((player) => !player.onField).toList();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() => _running = !_running);

    if (_running) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_running || !mounted) return;
        setState(() {
          _matchSeconds++;
          for (final player in _players) {
            if (player.onField) {
              player.playedSeconds++;
            }
          }
        });
      });
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _registerSubstitution() async {
    if (_onField.isEmpty || _bench.isEmpty) return;

    Player? playerOut;
    Player? playerIn;

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
                      'Cambio rápido',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '1. Selecciona quién sale',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _onField.map((player) {
                        return ChoiceChip(
                          label: Text('${player.number} · ${player.name.split(' ').first}'),
                          selected: playerOut?.id == player.id,
                          onSelected: (_) {
                            setSheetState(() => playerOut = player);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '2. Selecciona quién entra',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bench.map((player) {
                        return ChoiceChip(
                          label: Text('${player.number} · ${player.name.split(' ').first}'),
                          selected: playerIn?.id == player.id,
                          onSelected: (_) {
                            setSheetState(() => playerIn = player);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: playerOut != null && playerIn != null
                            ? () => Navigator.pop(context, true)
                            : null,
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Confirmar cambio'),
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

    if (confirmed != true || playerOut == null || playerIn == null) return;

    setState(() {
      playerOut!.onField = false;
      playerIn!.onField = true;
      _events.insert(
        0,
        MatchEvent(
          type: MatchEventType.substitution,
          matchSecond: _matchSeconds,
          description:
              'Sale ${playerOut!.number} ${playerOut!.name} · Entra ${playerIn!.number} ${playerIn!.name}',
          playerOutId: playerOut!.id,
          playerInId: playerIn!.id,
        ),
      );
    });

    _showUndoSnackBar('Cambio registrado');
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

    _showUndoSnackBar('Gol registrado');
  }

  void _showUndoSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: _undoLastEvent,
          ),
        ),
      );
  }

  void _undoLastEvent() {
    if (_events.isEmpty) return;

    setState(() {
      final event = _events.removeAt(0);

      switch (event.type) {
        case MatchEventType.substitution:
          final playerOut =
              _players.firstWhere((p) => p.id == event.playerOutId);
          final playerIn =
              _players.firstWhere((p) => p.id == event.playerInId);
          playerOut.onField = true;
          playerIn.onField = false;
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxSeconds = _players.fold<int>(
      1,
      (currentMax, player) =>
          player.playedSeconds > currentMax ? player.playedSeconds : currentMax,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partido en directo'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ScoreHeader(
              homeGoals: _homeGoals,
              awayGoals: _awayGoals,
              time: _formatTime(_matchSeconds),
              running: _running,
              onToggle: _toggleTimer,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _registerGoal,
                      icon: const Icon(Icons.sports_soccer),
                      label: const Text('Gol'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _registerSubstitution,
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Cambio'),
                    ),
                  ),
                ],
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
                      progress: player.playedSeconds / maxSeconds,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionTitle(title: 'Banquillo', count: _bench.length),
                  ..._bench.map(
                    (player) => _PlayerRow(
                      player: player,
                      time: _formatTime(player.playedSeconds),
                      progress: player.playedSeconds / maxSeconds,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Últimos eventos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_events.isNotEmpty)
                        TextButton.icon(
                          onPressed: _undoLastEvent,
                          icon: const Icon(Icons.undo, size: 18),
                          label: const Text('Deshacer'),
                        ),
                    ],
                  ),
                  if (_events.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Los cambios y goles aparecerán aquí.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._events.take(6).map(
                          (event) => Card(
                            child: ListTile(
                              leading: Icon(
                                event.type == MatchEventType.substitution
                                    ? Icons.swap_horiz
                                    : Icons.sports_soccer,
                              ),
                              title: Text(event.description),
                              trailing: Text(_formatTime(event.matchSecond)),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({
    required this.homeGoals,
    required this.awayGoals,
    required this.time,
    required this.running,
    required this.onToggle,
  });

  final int homeGoals;
  final int awayGoals;
  final String time;
  final bool running;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            const Text('Jornada 24'),
            const SizedBox(height: 4),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'S.D. Ponferradina',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 70),
                Expanded(
                  child: Text(
                    'C.D. Ponferrada City',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text('$count'),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.time,
    required this.progress,
  });

  final Player player;
  final String time;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
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
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: progress < 0 ? 0 : (progress > 1 ? 1 : progress),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(99),
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
      ),
    );
  }
}
