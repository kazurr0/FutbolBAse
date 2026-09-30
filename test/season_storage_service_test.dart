import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:futbol_base/models/player.dart';
import 'package:futbol_base/services/season_storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('acumula minutos de temporada sin duplicar un mismo partido', () async {
    final storage = SeasonStorageService();

    final firstMatchPlayers = [
      Player(
        id: '7',
        number: 7,
        name: 'Mateo Otero Alvarez',
        onField: false,
        started: true,
        playedSeconds: 1200,
        firstHalfSeconds: 900,
        secondHalfSeconds: 300,
        goals: 1,
      ),
      Player(
        id: '8',
        number: 8,
        name: 'Nel Merayo Fernandez',
        onField: true,
        started: false,
        playedSeconds: 600,
        firstHalfSeconds: 0,
        secondHalfSeconds: 600,
      ),
    ];

    await storage.saveFinishedMatch(
      team: 'S.D. Ponferradina',
      opponent: 'C.D. Ponferrada City',
      round: '24',
      matchSeconds: 3000,
      goalsFor: 2,
      goalsAgainst: 1,
      players: firstMatchPlayers,
    );

    await storage.saveFinishedMatch(
      team: 'S.D. Ponferradina',
      opponent: 'C.D. Ponferrada City',
      round: '24',
      matchSeconds: 3000,
      goalsFor: 3,
      goalsAgainst: 1,
      players: firstMatchPlayers,
    );

    final matches = await storage.loadMatches();
    final totals = await storage.loadPlayerTotals();

    expect(matches, hasLength(1));
    expect(matches.single.goalsFor, 3);

    final mateo = totals.firstWhere((player) => player.id == '7');
    expect(mateo.playedSeconds, 1200);
    expect(mateo.appearances, 1);
    expect(mateo.starts, 1);
    expect(mateo.goals, 1);

    final nel = totals.firstWhere((player) => player.id == '8');
    expect(nel.playedSeconds, 600);
    expect(nel.appearances, 1);
    expect(nel.starts, 0);
    expect(nel.substituteAppearances, 1);
  });
}
