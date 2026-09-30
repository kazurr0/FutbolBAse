import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_base/services/lineup_import_service.dart';

void main() {
  test('parsea una alineación de la Federación', () {
    const text = '''
REAL FEDERACIÓN DE CASTILLA Y LEÓN DE FÚTBOL
2ª DIVISIÓN PROVINCIAL DE BENJAMINES - PRIMERA - LEÓN GRUPO 2 (EL BIERZO) - JORNADA 24
C.D. PONFERRADA CITY - S.D. PONFERRADINA S.A.D.
FECHA: 18-04-2026 13:00 - CAMPO: C.M. RAMÓN MARTÍNEZ 2.1
ALINEACIÓN DEL EQUIPO S.D. PONFERRADINA
S.A.D.
JUGADORES TITULARES
13
GARCIA PRADA, LEO
43868073N Benjamín
3
AIRA ALMEIDA, HUGO
43865863X Benjamín
5
CALZADO MARTINEZ, LEO
43868106E Benjamín
6
CALZADO MARTINEZ, LUKA
43868105K Benjamín
10
ALVAREZ GOMEZ, IAGO
44105741K Benjamín
11
GOMES VALERIO, DAVID LUCA
43868281J Benjamín
12
ROMANOS PONCELAS, HECTOR
44105051K Benjamín
JUGADORES SUPLENTES
2
FERNANDEZ SANCHEZ, MARTIN
44103819P Benjamín
4
PRIETO MOLINETE, ALEJANDRO
44102943Y Benjamín
7
OTERO ALVAREZ, MATEO
43865758C Benjamín
8
MERAYO FERNANDEZ, NEL
43866899B Benjamín
9
VUELTA IMBACHÍ, MATEO
44103448M Benjamín
REAL FEDERACIÓN DE CASTILLA Y LEÓN DE FÚTBOL
''';

    final result = LineupImportService().parseFederationLineup(text);

    expect(result.round, '24');
    expect(result.ourTeam, 'S.D. PONFERRADINA S.A.D.');
    expect(result.opponent, 'C.D. PONFERRADA CITY');
    expect(result.players, hasLength(12));
    expect(result.players.where((p) => p.onField), hasLength(7));
    expect(result.players.where((p) => !p.onField), hasLength(5));

    final goalkeeper = result.players.firstWhere((p) => p.number == 13);
    expect(goalkeeper.name, 'Leo Garcia Prada');

    final substitute = result.players.firstWhere((p) => p.number == 9);
    expect(substitute.name, 'Mateo Vuelta Imbachí');
    expect(substitute.onField, isFalse);
  });
}
