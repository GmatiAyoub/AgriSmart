class Vanne {
  final int id;
  final String nom;
  final int? parcelleId;
  final bool ouverte;

  const Vanne({
    required this.id,
    required this.nom,
    this.parcelleId,
    this.ouverte = false,
  });

  Vanne copyWith({String? nom, bool? ouverte}) {
    return Vanne(
      id: id,
      nom: nom ?? this.nom,
      parcelleId: parcelleId,
      ouverte: ouverte ?? this.ouverte,
    );
  }

  // etat cote API : "ouverte" | "fermee"
  factory Vanne.fromJson(Map<String, dynamic> json) {
    return Vanne(
      id: (json['id'] as num).toInt(),
      nom: (json['nom'] ?? '').toString(),
      parcelleId: (json['parcelleId'] as num?)?.toInt(),
      ouverte: json['etat'] == 'ouverte' || json['ouverte'] == true,
    );
  }
}
