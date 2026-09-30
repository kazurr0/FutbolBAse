import 'dart:async';
import 'package:flutter/material.dart';

import '../models/match_event.dart';
import '../models/player.dart';
import '../services/local_storage_service.dart';
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

  void _toggleTimer() {
    if (_isHalftime) return;
    setState(() => _running = !_running);
    _persistMatch();

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
        if (_matchSeconds % 5 == 0) {
          _persistMatch();
        }
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

    _persistMatch();
    _showNotice('Cambio registrado');
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
      setState(() {
        _isHalftime = false;
        _secondHalf = true;
        _running = true;
        _events.insert(
          0,
          MatchEvent(
            type: MatchEventType.secondHalf,
            matchSecond: _matchSeconds,
            description: 'Comienza la 2ª parte',
          ),
        );
      });
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_running || !mounted) return;
        setState(() {
          _matchSeconds++;
          for (final player in _players) {
            if (player.onField) player.playedSeconds++;
          }
        });
        if (_matchSeconds % 5 == 0) _persistMatch();
      });
      _persistMatch();
      _showNotice('2ª parte iniciada');
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
        case MatchEventType.halftime:
          _isHalftime = false;
          _secondHalf = false;
          break;
        case MatchEventType.secondHalf:
          _running = false;
          _isHalftime = true;
          _secondHalf = false;
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
                      progress: player.playedSeconds / plannedSeconds,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SectionTitle(title: 'Banquillo', count: _bench.length),
                  ..._bench.map(
                    (player) => _PlayerRow(
                      player: player,
                      time: _formatTime(player.playedSeconds),
                      progress: player.playedSeconds / plannedSeconds,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    homeTeam,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 70),
                Expanded(
                  child: Text(
                    awayTeam,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                  LinearProgressIndicator(
                    value: progress < 0 ? 0 : (progress > 1 ? 1 : progress),
                    minHeight: 4,
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
      );
  }
}
