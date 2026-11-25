class Zone {
  final String? id;
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
    this.id,
    this.vanneOuverte = false,
  });

  bool get besoinIrrigation => humidite < seuil;

  Zone copyWith({
    String? id,
    String? nom,
    String? culture,
    double? humidite,
    double? seuil,
    bool? vanneOuverte,
  }) {
    return Zone(
      nom ?? this.nom,
      culture ?? this.culture,
      humidite ?? this.humidite,
      seuil ?? this.seuil,
      id: id ?? this.id,
      vanneOuverte: vanneOuverte ?? this.vanneOuverte,
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
      'vanneOuverte': vanneOuverte,
    };
  }

  // Reconstruit une zone à partir d'un JSON (Support MongoDB _id & Node.js REST API keys)
  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      (json['nom'] ?? json['name'] ?? '').toString(),
      (json['culture'] ?? json['crop'] ?? '').toString(),
      ((json['humidite'] ?? json['humidity'] ?? 0) as num).toDouble(),
      ((json['seuil'] ?? json['threshold'] ?? 0) as num).toDouble(),
      id: (json['id'] ?? json['_id'])?.toString(),
      vanneOuverte: (json['vanneOuverte'] ?? json['isValveOpen'] ?? json['vanne_ouverte'] ?? false) as bool,
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