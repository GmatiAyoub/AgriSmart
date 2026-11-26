const bool utiliserFirebase = true;

/// URL du backend Node.js / Express (port 5224).
/// - Émulateur Android : http://10.0.2.2:5224/api
/// - Téléphone en USB  : `adb reverse tcp:5224 tcp:5224` puis http://127.0.0.1:5224/api
/// - Windows / Web     : http://localhost:5224/api
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5224/api',
);

/// Compte du backend (créé par `pnpm run seed`).
const String apiUsername = String.fromEnvironment('API_USERNAME', defaultValue: 'ayoub');
const String apiPassword = String.fromEnvironment('API_PASSWORD', defaultValue: 'ayoub12345678');
