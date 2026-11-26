import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agrismart/config.dart';
import 'package:agrismart/models/planification.dart';
import 'package:agrismart/models/vanne.dart';
import 'package:agrismart/models/zone.dart';

/// Erreur renvoyée par le backend (`{ message, code }`) ou erreur réseau.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code; // ex. PLANIFICATION_CHEVAUCHEMENT

  ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

/// Unique point d'accès au backend : connexion JWT, requêtes, conversion des erreurs.
class ApiService {
  final String baseUrl;
  final http.Client _client;

  String? _token;
  Future<void>? _connexionEnCours; // évite deux connexions simultanées

  ApiService({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? apiBaseUrl,
        _client = client ?? http.Client();

  void dispose() => _client.close();

  /// À appeler à la déconnexion de l'utilisateur.
  void deconnecter() => _token = null;

  // ---------------------------------------------------------------------------
  // Authentification (compte unique du backend)
  // ---------------------------------------------------------------------------

  Future<void> _assurerToken() {
    if (_token != null) return Future.value();
    return _connexionEnCours ??= _seConnecter().whenComplete(() => _connexionEnCours = null);
  }

  Future<void> _seConnecter() async {
    if (apiPassword.isEmpty) {
      throw ApiException(
        'Identifiants du serveur non configurés (lancez avec --dart-define=API_PASSWORD=...)',
      );
    }
    final data = await _requete(
      'POST',
      '/auth/login',
      corps: {'username': apiUsername, 'password': apiPassword},
      authentifie: false,
    );
    _token = (data as Map<String, dynamic>)['token'] as String;
  }

  // ---------------------------------------------------------------------------
  // Requête générique
  // ---------------------------------------------------------------------------

  Future<dynamic> _requete(
      String methode,
      String chemin, {
        Object? corps,
        bool authentifie = true,
        bool nouvelEssai = true,
      }) async {
    try {
      if (authentifie) await _assurerToken();

      final requete = http.Request(methode, Uri.parse('$baseUrl$chemin'));
      requete.headers['Accept'] = 'application/json';
      if (corps != null) {
        requete.headers['Content-Type'] = 'application/json; charset=UTF-8';
        requete.body = jsonEncode(corps);
      }
      if (authentifie) requete.headers['Authorization'] = 'Bearer $_token';

      final flux = await _client.send(requete).timeout(const Duration(seconds: 15));
      final reponse = await http.Response.fromStream(flux);

      // Token expiré (8 h) : on se reconnecte une fois, puis on rejoue la requête
      if (reponse.statusCode == 401 && authentifie && nouvelEssai) {
        _token = null;
        return await _requete(methode, chemin, corps: corps, nouvelEssai: false);
      }
      return _traiter(reponse);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException("Le serveur ne répond pas ($baseUrl)");
    } on http.ClientException {
      throw ApiException('Serveur injoignable ($baseUrl)');
    } on FormatException {
      throw ApiException('Réponse inattendue du serveur');
    }
  }

  dynamic _traiter(http.Response reponse) {
    dynamic corps;
    if (reponse.body.isNotEmpty) {
      try {
        corps = jsonDecode(utf8.decode(reponse.bodyBytes));
      } catch (_) {
        corps = null;
      }
    }

    if (reponse.statusCode >= 200 && reponse.statusCode < 300) return corps;

    var message = 'Erreur serveur (${reponse.statusCode})';
    String? code;
    if (corps is Map<String, dynamic>) {
      message = (corps['message'] ?? message).toString();
      code = corps['code']?.toString();
    }
    throw ApiException(message, statusCode: reponse.statusCode, code: code);
  }

  // ---------------------------------------------------------------------------
  // Parcelles (zones)
  // ---------------------------------------------------------------------------

  /// Parcelles + leurs vannes (2 requêtes : le détail des vannes n'est pas dans la liste).
  Future<List<Zone>> getZones() async {
    await _assurerToken();
    final resultats = await Future.wait([
      _requete('GET', '/parcelles'),
      _requete('GET', '/vannes'),
    ]);

    final vannesParParcelle = <String, List<Vanne>>{};
    for (final v in (resultats[1] as List).cast<Map<String, dynamic>>()) {
      vannesParParcelle
          .putIfAbsent(v['parcelleId'].toString(), () => [])
          .add(Vanne.fromJson(v));
    }

    return (resultats[0] as List).cast<Map<String, dynamic>>().map((p) {
      final zone = Zone.fromJson(p);
      return zone.copyWith(vannes: vannesParParcelle[zone.id] ?? const <Vanne>[]);
    }).toList();
  }

  Map<String, dynamic> _corpsParcelle(Zone z) => {
    'nom': z.nom,
    'culture': z.culture,
    'humidite': z.humidite,
    'seuil': z.seuil,
  };

  /// Crée la parcelle puis ses vannes. Si une vanne échoue, la parcelle est supprimée.
  Future<void> creerZone(Zone zone) async {
    final creee = await _requete('POST', '/parcelles', corps: _corpsParcelle(zone));
    final id = (creee as Map<String, dynamic>)['id'].toString();

    try {
      for (final vanne in zone.vannes) {
        await creerVanne(id, vanne.nom);
      }
      if (zone.auMoinsUneVanneOuverte && zone.vannes.isNotEmpty) {
        await irriguer(id, true);
      }
    } catch (_) {
      await _requete('DELETE', '/parcelles/$id').catchError((_) {});
      rethrow;
    }
  }

  /// Modifie uniquement la parcelle (les vannes se gèrent séparément).
  Future<void> modifierZone(String id, Zone zone) =>
      _requete('PUT', '/parcelles/$id', corps: _corpsParcelle(zone));

  Future<void> supprimerZone(String id) => _requete('DELETE', '/parcelles/$id');

  /// Ouvre ou ferme toutes les vannes d'une parcelle.
  Future<void> irriguer(String parcelleId, bool ouvrir) => _requete(
    'POST',
    '/parcelles/$parcelleId/irrigation',
    corps: {'action': ouvrir ? 'ouvrir' : 'fermer'},
  );

  // ---------------------------------------------------------------------------
  // Vannes
  // ---------------------------------------------------------------------------

  Future<void> creerVanne(String parcelleId, String nom) => _requete(
    'POST',
    '/vannes',
    corps: {'nom': nom, 'parcelleId': int.parse(parcelleId)},
  );

  Future<void> renommerVanne(String vanneId, String nom) =>
      _requete('PUT', '/vannes/$vanneId', corps: {'nom': nom});

  Future<void> supprimerVanne(String vanneId) => _requete('DELETE', '/vannes/$vanneId');

  Future<void> commanderVanne(String vanneId, bool ouvrir) => _requete(
    'POST',
    '/vannes/$vanneId/commande',
    corps: {'action': ouvrir ? 'ouvrir' : 'fermer'},
  );

  // ---------------------------------------------------------------------------
  // Planifications
  // ---------------------------------------------------------------------------

  Future<List<PlanificationIrrigation>> getPlanifications() async {
    final data = await _requete('GET', '/planifications');
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(PlanificationIrrigation.fromJson)
        .toList();
  }

  Future<void> creerPlanification(PlanificationIrrigation p) =>
      _requete('POST', '/planifications', corps: p.versApi(creation: true));

  Future<void> modifierPlanification(String id, PlanificationIrrigation p) =>
      _requete('PUT', '/planifications/$id', corps: p.versApi());

  Future<void> activerPlanification(String id, bool active) =>
      _requete('PUT', '/planifications/$id', corps: {'active': active});

  Future<void> supprimerPlanification(String id) => _requete('DELETE', '/planifications/$id');
}
