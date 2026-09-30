import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_base/models/match_event.dart';
import 'package:futbol_base/services/club_badge_catalog.dart';

void main() {
  test('conserva un bloque de cambios múltiples al serializar', () {
    final event = MatchEvent(
      type: MatchEventType.substitution,
      matchSecond: 820,
      description: 'Cambios múltiples',
      playerOutIds: const ['3', '5', '6'],
      playerInIds: const ['2', '7', '8'],
    );

    final restored = MatchEvent.fromJson(event.toJson());

    expect(restored.allPlayerOutIds, ['3', '5', '6']);
    expect(restored.allPlayerInIds, ['2', '7', '8']);
    expect(restored.matchSecond, 820);
  });

  test('mantiene compatibilidad con cambios antiguos de un jugador', () {
    final restored = MatchEvent.fromJson({
      'type': 'substitution',
      'matchSecond': 400,
      'description': 'Cambio',
      'playerOutId': '3',
      'playerInId': '2',
    });

    expect(restored.allPlayerOutIds, ['3']);
    expect(restored.allPlayerInIds, ['2']);
  });

  test('resuelve variantes de nombre para los escudos conocidos', () {
    expect(
      ClubBadgeCatalog.bytesFor('C.D. Ponferrada City Benjamín'),
      isNotNull,
    );
    expect(
      ClubBadgeCatalog.bytesFor('S.D. Ponferradina S.A.D.'),
      isNotNull,
    );
  });
}
