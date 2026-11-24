class Zone {
  final String nom;
  final String culture;
  double humidite;
  final double seuil;
  final bool vanneOuverte;

  Zone(
      this.nom,
      this.culture,
      this.humidite,
      this.seuil, {
        this.vanneOuverte = false,
      });

  bool get besoinIrrigation => humidite < seuil;

  // Conversion en JSON (pour l'enregistrer sur l'appareil)
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'culture': culture,
      'humidite': humidite,
      'seuil': seuil,
      'vanneOuverte': vanneOuverte,
    };
  }

  // Reconstruit une zone à partir d'un JSON
  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      json['nom'] as String,
      json['culture'] as String,
      (json['humidite'] as num).toDouble(),
      (json['seuil'] as num).toDouble(),
      vanneOuverte: (json['vanneOuverte'] as bool?) ?? false,
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