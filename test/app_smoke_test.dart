import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_base/main.dart';

void main() {
  testWidgets('Muestra la pantalla de partido', (tester) async {
    await tester.pumpWidget(const FutbolBaseApp());

    expect(find.text('Partido en directo'), findsOneWidget);
    expect(find.text('Gol'), findsOneWidget);
    expect(find.text('Cambio'), findsOneWidget);
  });
}
