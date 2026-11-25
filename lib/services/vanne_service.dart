import 'package:agrismart/models/vanne.dart';
import 'package:agrismart/services/api_client.dart';

class VanneService {
  // GET /api/vannes  ou  GET /api/vannes?parcelleId=1
  Future<List<Vanne>> lister({int? parcelleId}) async {
    final donnees = await ApiClient.get(
      '/vannes',
      query: parcelleId == null ? null : {'parcelleId': '$parcelleId'},
    );
    return ApiClient.liste(donnees)
        .whereType<Map<String, dynamic>>()
        .map(Vanne.fromJson)
        .toList();
  }

  // POST /api/vannes  (creee fermee)
  Future<void> creer(String nom, int parcelleId) async {
    await ApiClient.post('/vannes', corps: {'nom': nom, 'parcelleId': parcelleId});
  }

  // PUT /api/vannes/:id
  Future<void> renommer(int id, String nom) async {
    await ApiClient.put('/vannes/$id', corps: {'nom': nom});
  }

  // DELETE /api/vannes/:id
  Future<void> supprimer(int id) async {
    await ApiClient.delete('/vannes/$id');
  }

  // POST /api/vannes/:id/commande
  Future<void> commander(int id, {required bool ouvrir}) async {
    await ApiClient.post(
      '/vannes/$id/commande',
      corps: {'action': ouvrir ? 'ouvrir' : 'fermer'},
    );
  }
}
