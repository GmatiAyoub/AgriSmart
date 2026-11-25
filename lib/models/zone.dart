class Zone {
  final String nom;
  final String culture;
  double humidite;
  final double seuil;
  bool vanneOuverte;

  Zone(
    this.nom,
    this.culture,
    this.humidite,
    this.seuil, {
    this.vanneOuverte = false,
  });

  bool get besoinIrrigation => humidite < seuil;

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      json['nom'] as String? ?? '',
      json['culture'] as String? ?? '',
      (json['humidite'] as num?)?.toDouble() ?? 0.0,
      (json['seuil'] as num?)?.toDouble() ?? 0.0,
      vanneOuverte: (json['vanneOuverte'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'culture': culture,
      'humidite': humidite,
      'seuil': seuil,
      'vanneOuverte': vanneOuverte,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Zone &&
          runtimeType == other.runtimeType &&
          nom == other.nom;

  @override
  int get hashCode => nom.hashCode;
}

/// Calcule l'humidité moyenne d'une liste de zones (en %)
double humiditeMoyenne(List<Zone> zones) {
  if (zones.isEmpty) return 0;
  final somme = zones.fold<double>(0, (total, zone) => total + zone.humidite);
  return somme / zones.length;
}
