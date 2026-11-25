const bool utiliserFirebase = true;

/// Configuration du serveur Backend Node.js avec Express.js REST API
/// Par défaut sur Android Emulator: http://10.0.2.2:3000/api
/// Sur Web / iOS / Device physique: remplacer par l'IP de votre serveur Node.js (ex: http://192.168.1.50:3000/api)
const String apiBaseUrlDefault = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api',
);

/// Active l'utilisation du backend HTTP REST Node.js pour les zones et vannes
const bool utiliserBackendRest = true;
