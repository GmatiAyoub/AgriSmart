const bool utiliserFirebase = true;

/// URL du backend Node.js / Express.
/// - Émulateur Android : http://10.0.2.2:5224/api
/// - Téléphone en USB  : `adb reverse tcp:5224 tcp:5224` puis http://localhost:5224/api
/// - Téléphone en Wi-Fi : http://IP_DU_PC:5224/api
/// Se règle au lancement : flutter run --dart-define=API_BASE_URL=...
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5224/api',
);

/// Compte du backend (créé par `pnpm run seed`). Le mot de passe ne doit JAMAIS être écrit
/// dans le code : flutter run --dart-define=API_PASSWORD=...
const String apiUsername = String.fromEnvironment('API_USERNAME', defaultValue: 'ayoub');
const String apiPassword = String.fromEnvironment('API_PASSWORD');
