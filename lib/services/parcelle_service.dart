import 'package:agrismart/models/parcelle_api.dart';
import 'package:agrismart/services/api_client.dart';

class ParcelleService {
  // GET /api/parcelles
  Future<List<ParcelleApi>> lister() async {
    final donnees = await ApiClient.get('/parcelles');
    return ApiClient.liste(donnees)
        .whereType<Map<String, dynamic>>()
        .map(ParcelleApi.fromJson)
        .toList();
  }

  // POST /api/parcelles
  Future<void> creer(String nom) async {
    await ApiClient.post('/parcelles', corps: {'nom': nom});
  }

  // PUT /api/parcelles/:id
  Future<void> renommer(int id, String nom) async {
    await ApiClient.put('/parcelles/$id', corps: {'nom': nom});
  }

  // POST /api/parcelles/:id/irrigation  (ouvre / ferme toutes ses vannes)
  Future<void> irrigation(int id, {required bool ouvrir}) async {
    await ApiClient.post(
      '/parcelles/$id/irrigation',
      corps: {'action': ouvrir ? 'ouvrir' : 'fermer'},
    );
  }

  // Retourne la parcelle du serveur portant ce nom, et la cree si absente
  Future<ParcelleApi> assurer(String nom) async {
    ParcelleApi? chercher(List<ParcelleApi> liste) {
      for (final p in liste) {
        if (ParcelleApi.cle(p.nom) == ParcelleApi.cle(nom)) return p;
      }
      return null;
    }

    final existante = chercher(await lister());
    if (existante != null) return existante;

    await creer(nom);
    final creee = chercher(await lister());
    if (creee == null) {
      throw const ApiException('Impossible de créer la parcelle sur le serveur');
    }
    return creee;
  }
}
