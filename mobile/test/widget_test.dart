import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/main.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/planification_provider.dart';
import 'package:agrismart/providers/reglages_provider.dart';
import 'package:agrismart/providers/meteo_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/services/auth_locale_service.dart';
import 'package:agrismart/services/traduction_service.dart';

void main() {
  testWidgets('L\'application se lance sans erreur', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthLocaleService();
    final traductionService = TraductionService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
          ChangeNotifierProvider(create: (_) => ReglagesProvider(prefs)),
          ChangeNotifierProvider(
            create: (context) => ZonesProvider(prefs, context.read<AuthProvider>()),
          ),
          ChangeNotifierProxyProvider<ZonesProvider, PlanificationProvider>(
            create: (context) => PlanificationProvider(
              prefs,
              context.read<AuthProvider>(),
              zonesProvider: context.read<ZonesProvider>(),
            ),
            update: (context, zonesProvider, planificationProvider) {
              planificationProvider?.mettreAJourZonesProvider(zonesProvider);
              return planificationProvider!;
            },
          ),
          ChangeNotifierProvider(create: (_) => MeteoProvider(prefs)),
          ChangeNotifierProvider(create: (_) => TraductionProvider(traductionService)),
        ],
        child: const AgriSmartApp(),
      ),
    );

    expect(find.byType(AgriSmartApp), findsOneWidget);
  });
}