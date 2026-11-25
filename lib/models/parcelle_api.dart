// Parcelle telle que renvoyee par le backend (GET /api/parcelles).
class ParcelleApi {
  final int id;
  final String nom;
  final int nombreVannes;
  final bool irrigationActive;

  const ParcelleApi({
    required this.id,
    required this.nom,
    this.nombreVannes = 0,
    this.irrigationActive = false,
  });

  // Cle de rapprochement entre une zone de l'app et une parcelle du serveur
  static String cle(String nom) => nom.trim().toLowerCase();

  factory ParcelleApi.fromJson(Map<String, dynamic> json) {
    return ParcelleApi(
      id: (json['id'] as num).toInt(),
      nom: (json['nom'] ?? '').toString(),
      nombreVannes: (json['nombreVannes'] as num?)?.toInt() ?? 0,
      irrigationActive: json['irrigationActive'] == true,
    );
  }
}
