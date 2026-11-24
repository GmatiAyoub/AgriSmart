import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart'; // 👈 Ajout ML Kit
import 'package:agrismart/config.dart';
import 'package:agrismart/firebase_options.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart'; // 👈 Ajout Provider
import 'package:agrismart/screens/auth_gate.dart';
import 'package:agrismart/services/auth_locale_service.dart';
import 'package:agrismart/services/auth_service.dart';
import 'package:agrismart/services/firebase_auth_service.dart';
import 'package:agrismart/services/traduction_service.dart'; // 👈 Ajout Service
import 'package:agrismart/theme/app_theme.dart';
import 'package:agrismart/providers/meteo_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AuthService authService;

  // C'est ICI que la magie opère
  if (utiliserFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    authService = FirebaseAuthService();
  } else {
    authService = AuthLocaleService();
  }

  // Instanciation du service de traduction
  final traductionService = TraductionService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => ZonesProvider()),
        ChangeNotifierProvider(create: (_) => MeteoProvider()..charger()),

        // 👇 Ajout du Provider de traduction
        ChangeNotifierProvider(
          create: (_) => TraductionProvider(traductionService)
          // On lance la préparation du modèle en arrière-plan au démarrage.
          // (Attention : cela téléchargera ~30 Mo si le modèle n'est pas présent.
          // Pour une démo, il est plus sûr de déclencher cette action via un bouton).
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
      themeMode: ThemeMode.system,
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