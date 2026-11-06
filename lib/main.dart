import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/app_shell.dart';
import 'package:agrismart/theme/app_theme.dart';

void main() {
  runApp(
    // 🔌 On branche le Provider tout en haut !
    ChangeNotifierProvider(
      create: (_) => ZonesProvider(),
      child: const AgriSmartApp(),
    ),
  );
}

class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSmart',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      // darkTheme: AppTheme.sombre(),
      // themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}