import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:agrismart/config.dart';
import 'package:agrismart/firebase_options.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/reglages_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/planification_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/screens/auth_gate.dart';
import 'package:agrismart/services/auth_locale_service.dart';
import 'package:agrismart/services/auth_service.dart';
import 'package:agrismart/services/firebase_auth_service.dart';
import 'package:agrismart/services/traduction_service.dart';
import 'package:agrismart/theme/app_theme.dart';
import 'package:agrismart/providers/meteo_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthService authService;

  if (utiliserFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    authService = FirebaseAuthService();
  } else {
    authService = AuthLocaleService();
  }

  // Stockage local : ouvert une seule fois, transmis aux providers
  final prefs = await SharedPreferences.getInstance();

  final traductionService = TraductionService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => ReglagesProvider(prefs)),
        // L'AuthProvider doit être déclaré AVANT le ZonesProvider
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
        ChangeNotifierProvider(create: (_) => MeteoProvider(prefs)..charger()),
        ChangeNotifierProvider(
          create: (_) => TraductionProvider(traductionService)
            ..preparerModele(TranslateLanguage.arabic),
        ),
      ],
      child: const AgriSmartApp(),
    ),
  );
}

class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();

    return MaterialApp(
      title: 'AgriSmart',
      theme: AppTheme.clair(),
      darkTheme: AppTheme.sombre(),
      themeMode: context.watch<ReglagesProvider>().themeMode,
      locale: traduction.locale,
      builder: (context, child) {
        return Directionality(
          textDirection: traduction.estArabe ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}