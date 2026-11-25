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

  // Conversion en JSON (pour l'enregistrer sur l'appareil ou l'envoyer au backend REST)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'culture': culture,
      'humidite': humidite,
      'seuil': seuil,
      'vannes': vannes.map((v) => v.toJson()).toList(),
      'vanneOuverte': auMoinsUneVanneOuverte,
    };
  }

  // Reconstruit une zone à partir d'un JSON (Support MongoDB _id & Node.js REST API keys)
  factory Zone.fromJson(Map<String, dynamic> json) {
    List<Vanne> listeVannes = [];
    if (json['vannes'] != null && json['vannes'] is List) {
      listeVannes = (json['vannes'] as List)
          .map((v) => Vanne.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    final bool estOuverteBase =
        (json['vanneOuverte'] ?? json['isValveOpen'] ?? json['vanne_ouverte'] ?? false) as bool;

    if (listeVannes.isEmpty) {
      listeVannes = [Vanne(nom: 'Vanne 1', estOuverte: estOuverteBase)];
    }

    return Zone(
      (json['nom'] ?? json['name'] ?? '').toString(),
      (json['culture'] ?? json['crop'] ?? '').toString(),
      ((json['humidite'] ?? json['humidity'] ?? 0) as num).toDouble(),
      ((json['seuil'] ?? json['threshold'] ?? 0) as num).toDouble(),
      id: (json['id'] ?? json['_id'])?.toString(),
      vannes: listeVannes,
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
