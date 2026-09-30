import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_base/main.dart';

void main() {
  testWidgets('Muestra el panel principal y preparación del partido', (tester) async {
    await tester.pumpWidget(const FutbolBaseApp());
    await tester.pumpAndSettle();

    expect(find.text('Preparar partido'), findsOneWidget);
    expect(find.text('Empezar partido'), findsOneWidget);
    expect(find.text('Importar acta'), findsWidgets);
    expect(find.text('Resumen de temporada'), findsOneWidget);
  });
}
