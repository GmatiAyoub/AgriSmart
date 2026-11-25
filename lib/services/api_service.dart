import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agrismart/config.dart';
import 'package:agrismart/models/zone.dart';

/// Exception personnalisée pour les erreurs API REST HTTP
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException: $message (Code: $statusCode)';
}

/// Service centralisé de gestion des requêtes HTTP REST pour la communication avec le backend Node.js / Express
class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? apiBaseUrlDefault,
        _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  /// [GET] Consulter toutes les zones et leurs vannes
  Future<List<Zone>> getZones() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/zones'), headers: _headers)
          .timeout(const Duration(seconds: 6));

      final data = _traiterReponse(response);
      if (data is List) {
        return data.map((item) => Zone.fromJson(item as Map<String, dynamic>)).toList();
      } else if (data is Map<String, dynamic> && data.containsKey('zones')) {
        final list = data['zones'] as List;
        return list.map((item) => Zone.fromJson(item as Map<String, dynamic>)).toList();
      } else if (data is Map<String, dynamic> && data.containsKey('data')) {
        final list = data['data'] as List;
        return list.map((item) => Zone.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } on SocketException catch (_) {
      throw ApiException('Serveur backend REST indisponible ($baseUrl)');
    } on TimeoutException catch (_) {
      throw ApiException('Délai d\'attente dépassé lors de la connexion au serveur');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la récupération des zones: $e');
    }
  }

  /// [GET] Consulter une zone spécifique par ID
  Future<Zone> getZoneById(String id) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/zones/$id'), headers: _headers)
          .timeout(const Duration(seconds: 6));

      final data = _traiterReponse(response);
      return Zone.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la consultation de la zone: $e');
    }
  }

  /// [POST] Ajouter une nouvelle zone / vanne
  Future<Zone> ajouterZone(Zone zone) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/zones'),
            headers: _headers,
            body: jsonEncode(zone.toJson()),
          )
          .timeout(const Duration(seconds: 6));

      final data = _traiterReponse(response);
      if (data is Map<String, dynamic>) {
        final obj = data.containsKey('zone') ? data['zone'] : (data.containsKey('data') ? data['data'] : data);
        return Zone.fromJson(obj as Map<String, dynamic>);
      }
      return zone;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de l\'ajout de la zone: $e');
    }
  }

  /// [PUT] Modifier complètement une zone / vanne
  Future<Zone> modifierZone(String id, Zone zone) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl/zones/$id'),
            headers: _headers,
            body: jsonEncode(zone.toJson()),
          )
          .timeout(const Duration(seconds: 6));

      final data = _traiterReponse(response);
      if (data is Map<String, dynamic>) {
        final obj = data.containsKey('zone') ? data['zone'] : (data.containsKey('data') ? data['data'] : data);
        return Zone.fromJson(obj as Map<String, dynamic>);
      }
      return zone;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la modification de la zone: $e');
    }
  }

  /// [PATCH] Modifier partiellement une zone / vanne
  Future<Zone> patchZone(String id, Map<String, dynamic> modifications) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('$baseUrl/zones/$id'),
            headers: _headers,
            body: jsonEncode(modifications),
          )
          .timeout(const Duration(seconds: 6));

      final data = _traiterReponse(response);
      if (data is Map<String, dynamic>) {
        final obj = data.containsKey('zone') ? data['zone'] : (data.containsKey('data') ? data['data'] : data);
        return Zone.fromJson(obj as Map<String, dynamic>);
      }
      throw ApiException('Réponse inattendue lors de la mise à jour');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la mise à jour partielle: $e');
    }
  }

  /// [DELETE] Supprimer une zone / vanne
  Future<void> supprimerZone(String id) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl/zones/$id'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 6));

      _traiterReponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors de la suppression de la zone: $e');
    }
  }

  /// [PATCH] Ouverture ou Fermeture de la vanne d'une zone
  Future<Zone> changerEtatVanne(String id, bool ouverte) async {
    final payload = {
      'vanneOuverte': ouverte,
      'action': ouverte ? 'ouverture' : 'fermeture',
    };

    try {
      // Tentative vers endpoint dédié /zones/:id/vanne ou fallback /zones/:id
      late http.Response response;
      try {
        response = await _client
            .patch(
              Uri.parse('$baseUrl/zones/$id/vanne'),
              headers: _headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 6));
      } catch (_) {
        response = await _client
            .patch(
              Uri.parse('$baseUrl/zones/$id'),
              headers: _headers,
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 6));
      }

      final data = _traiterReponse(response);
      if (data is Map<String, dynamic>) {
        final obj = data.containsKey('zone') ? data['zone'] : (data.containsKey('data') ? data['data'] : data);
        return Zone.fromJson(obj as Map<String, dynamic>);
      }
      throw ApiException('Format de réponse invalide');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Erreur lors du changement d\'état de la vanne: $e');
    }
  }

  /// Centralisation du traitement des réponses et des exceptions HTTP
  dynamic _traiterReponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        body = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }

    String message = 'Erreur HTTP $statusCode';
    if (body is Map<String, dynamic>) {
      message = body['message'] ?? body['erreur'] ?? body['error'] ?? message;
    }

    throw ApiException(message, statusCode: statusCode, details: body);
  }
}
