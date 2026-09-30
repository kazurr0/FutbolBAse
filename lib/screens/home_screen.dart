import 'package:flutter/material.dart';

import '../services/local_storage_service.dart';
import 'live_match_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final LocalStorageService _storage = LocalStorageService();
  MatchSnapshot? _savedMatch;
  final _teamController = TextEditingController(text: 'S.D. Ponferradina');
  final _rivalController = TextEditingController(text: 'C.D. Ponferrada City');
  final _roundController = TextEditingController(text: '24');
  final _minutesController = TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    _loadSavedMatch();
  }

  Future<void> _loadSavedMatch() async {
    final snapshot = await _storage.loadMatch();
    if (!mounted) return;
    setState(() => _savedMatch = snapshot);
  }

  void _continueMatch() {
    final match = _savedMatch;
    if (match == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveMatchScreen(
          homeTeam: match.homeTeam,
          awayTeam: match.awayTeam,
          round: match.round,
          plannedMinutes: match.plannedMinutes,
        ),
      ),
    ).then((_) => _loadSavedMatch());
  }

  @override
  void dispose() {
    _teamController.dispose();
    _rivalController.dispose();
    _roundController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _startMatch() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveMatchScreen(
          homeTeam: _teamController.text.trim(),
          awayTeam: _rivalController.text.trim(),
          round: _roundController.text.trim(),
          plannedMinutes: int.parse(_minutesController.text.trim()),
        ),
      ),
    ).then((_) => _loadSavedMatch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FutbolBAse'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Nuevo partido',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configura el encuentro y entra directamente al control de minutos.',
            ),
            const SizedBox(height: 16),
            if (_savedMatch != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Continuar partido guardado'),
                  subtitle: Text(
                    '${_savedMatch!.homeTeam} vs ${_savedMatch!.awayTeam} · Jornada ${_savedMatch!.round}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _continueMatch,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _teamController,
                    decoration: const InputDecoration(
                      labelText: 'Nuestro equipo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Introduce el equipo'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _rivalController,
                    decoration: const InputDecoration(
                      labelText: 'Rival',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Introduce el rival'
                            : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _roundController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jornada',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Obligatorio'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minutesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duración (min)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final minutes = int.tryParse(value ?? '');
                            if (minutes == null || minutes <= 0) {
                              return 'Minutos válidos';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _startMatch,
                      icon: const Icon(Icons.play_arrow),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Empezar partido'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Importar alineación desde PDF'),
                subtitle: const Text('Lo añadiremos en la siguiente fase.'),
                trailing: const Icon(Icons.lock_clock),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
