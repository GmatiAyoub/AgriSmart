import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agrismart/api_config.dart';

class ApiException implements Exception {
  final String message;
  final String? code; // ex : PLANIFICATION_CHEVAUCHEMENT
  final int? statusCode;

  const ApiException(this.message, {this.code, this.statusCode});

  @override
  String toString() => message;
}

// Client HTTP du backend : login automatique, header Bearer, gestion des erreurs.
class ApiClient {
  static String? _token;

  static Future<dynamic> get(String chemin, {Map<String, String>? query}) =>
      _requete('GET', chemin, query: query);

  static Future<dynamic> post(String chemin, {Map<String, dynamic>? corps}) =>
      _requete('POST', chemin, corps: corps);

  static Future<dynamic> put(String chemin, {Map<String, dynamic>? corps}) =>
      _requete('PUT', chemin, corps: corps);

  static Future<dynamic> delete(String chemin) => _requete('DELETE', chemin);

  // Extrait une liste d'une reponse (liste directe ou objet contenant une liste)
  static List<dynamic> liste(dynamic donnees) {
    if (donnees is List) return donnees;
    if (donnees is Map) {
      for (final valeur in donnees.values) {
        if (valeur is List) return valeur;
      }
    }
    return const [];
  }

  static Future<void> _connecter() async {
    final reponse = await _envoyer(
      'POST',
      '/auth/login',
      corps: {'username': apiUsername, 'password': apiPassword},
      avecToken: false,
    );
    final donnees = _decoder(reponse);
    final token = donnees is Map ? donnees['token'] : null;
    if (token is! String) {
      throw const ApiException('Réponse de connexion illisible');
    }
    _token = token;
  }

  static Future<dynamic> _requete(
      String methode,
      String chemin, {
        Map<String, dynamic>? corps,
        Map<String, String>? query,
      }) async {
    if (_token == null) await _connecter();

    var reponse = await _envoyer(methode, chemin, corps: corps, query: query);
    if (reponse.statusCode == 401) {
      // token expire : on se reconnecte une fois
      _token = null;
      await _connecter();
      reponse = await _envoyer(methode, chemin, corps: corps, query: query);
    }
    return _decoder(reponse);
  }

  static Future<http.Response> _envoyer(
      String methode,
      String chemin, {
        Map<String, dynamic>? corps,
        Map<String, String>? query,
        bool avecToken = true,
      }) async {
    var uri = Uri.parse('$apiBaseUrl$chemin');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final entetes = {
      'Content-Type': 'application/json',
      if (avecToken && _token != null) 'Authorization': 'Bearer $_token',
    };
    final contenu = corps == null ? null : jsonEncode(corps);

    try {
      final futur = switch (methode) {
        'GET' => http.get(uri, headers: entetes),
        'POST' => http.post(uri, headers: entetes, body: contenu),
        'PUT' => http.put(uri, headers: entetes, body: contenu),
        'DELETE' => http.delete(uri, headers: entetes),
        _ => throw ArgumentError(methode),
      };
      return await futur.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException('Le serveur met trop de temps à répondre');
    } catch (_) {
      throw const ApiException('Pas de connexion au serveur');
    }
  }

  static dynamic _decoder(http.Response reponse) {
    final ok = reponse.statusCode >= 200 && reponse.statusCode < 300;
    if (ok) {
      if (reponse.statusCode == 204 || reponse.body.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(reponse.bodyBytes));
      } catch (_) {
        throw const ApiException('Réponse du serveur illisible');
      }
    }

    // erreurs : {"message":"...","code":"..."}
    var message = 'Erreur du serveur (${reponse.statusCode})';
    String? code;
    try {
      final donnees = jsonDecode(utf8.decode(reponse.bodyBytes));
      if (donnees is Map) {
        message = (donnees['message'] ?? message).toString();
        code = donnees['code']?.toString();
      }
    } catch (_) {}
    throw ApiException(message, code: code, statusCode: reponse.statusCode);
  }
}
