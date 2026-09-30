import 'package:flutter_test/flutter_test.dart';
import 'package:futbol_base/main.dart';

void main() {
  testWidgets('Muestra la configuración del partido', (tester) async {
    await tester.pumpWidget(const FutbolBaseApp());

    expect(find.text('Nuevo partido'), findsOneWidget);
    expect(find.text('Empezar partido'), findsOneWidget);
    expect(find.text('Importar alineación desde PDF'), findsOneWidget);
  });
}
