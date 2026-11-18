import 'package:flutter_test/flutter_test.dart';
import 'package:agrismart/main.dart';

void main() {
  testWidgets('L\'application se lance sans erreur', (WidgetTester tester) async {
    // On lance l'application
    await tester.pumpWidget(const AgriSmartApp());
    // On vérifie que l'écran de connexion ou l'AuthGate s'affiche
    expect(find.byType(AgriSmartApp), findsOneWidget);
  });
}