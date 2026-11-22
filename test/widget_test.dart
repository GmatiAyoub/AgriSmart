import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/main.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/interventions_provider.dart';
import 'package:agrismart/providers/meteo_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/services/auth_locale_service.dart';
import 'package:agrismart/services/traduction_service.dart';

void main() {
  testWidgets('L\'application se lance sans erreur', (WidgetTester tester) async {
    final authService = AuthLocaleService();
    final traductionService = TraductionService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
          ChangeNotifierProvider(create: (_) => ZonesProvider()),
          ChangeNotifierProvider(create: (_) => InterventionsProvider()),
          ChangeNotifierProvider(create: (_) => MeteoProvider()),
          ChangeNotifierProvider(create: (_) => TraductionProvider(traductionService)),
        ],
        child: const AgriSmartApp(),
      ),
    );

    expect(find.byType(AgriSmartApp), findsOneWidget);
  });
}