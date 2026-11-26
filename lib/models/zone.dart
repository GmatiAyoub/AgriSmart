import 'package:agrismart/models/vanne.dart';

class Zone {
  final String? id;
  final String nom;
  final String culture;
  double humidite;
  final double seuil;
  final List<Vanne> vannes;

  Zone(
      this.nom,
      this.culture,
      this.humidite,
      this.seuil, {
        this.id,
        List<Vanne>? vannes,
        bool vanneOuverte = false,
      }) : vannes = vannes ??
      [
        Vanne(nom: 'Vanne 1', estOuverte: vanneOuverte),
      ];

  bool get besoinIrrigation => humidite < seuil;
  bool get auMoinsUneVanneOuverte => vannes.any((v) => v.estOuverte);
  bool get toutesVannesOuvertes => vannes.isNotEmpty && vannes.every((v) => v.estOuverte);
  int get nombreVannesOuvertes => vannes.where((v) => v.estOuverte).length;

  bool get vanneOuverte => auMoinsUneVanneOuverte;

  Zone copyWith({
    String? id,
    String? nom,
    String? culture,
    double? humidite,
    double? seuil,
    List<Vanne>? vannes,
  }) {
    return Zone(
      nom ?? this.nom,
      culture ?? this.culture,
      humidite ?? this.humidite,
      seuil ?? this.seuil,
      id: id ?? this.id,
      vannes: vannes ?? List.from(this.vannes),
    );
  }

  /// Reconstruit une zone (parcelle) à partir de la réponse du backend.
  /// Les vannes sont ajoutées à part (voir ApiService.getZones).
  factory Zone.fromJson(Map<String, dynamic> json) {
    final vannes = json['vannes'] is List
        ? (json['vannes'] as List)
        .map((v) => Vanne.fromJson(v as Map<String, dynamic>))
        .toList()
        : <Vanne>[];

    return Zone(
      (json['nom'] ?? '').toString(),
      (json['culture'] ?? '').toString(),
      ((json['humidite'] ?? 0) as num).toDouble(),
      ((json['seuil'] ?? 0) as num).toDouble(),
      id: json['id']?.toString(),
      vannes: vannes,
    );
  }
}

// Calcule l'humidité moyenne des zones
double humiditeMoyenne(List<Zone> zones) {
  if (zones.isEmpty) return 0;

  final somme = zones.fold<double>(0, (acc, z) => acc + z.humidite);

  return somme / zones.length;
}

// Retourne le diagnostic d'une zone
String diagnostic(Zone zone) {
  return zone.besoinIrrigation
      ? "Besoin d'irrigation"
      : "Sol correct";
}
