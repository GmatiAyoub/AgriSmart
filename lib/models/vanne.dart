class Vanne {
  final String? id;
  final String nom;
  final bool estOuverte;

  Vanne({
    required this.nom,
    this.estOuverte = false,
    this.id,
  });

  Vanne copyWith({
    String? id,
    String? nom,
    bool? estOuverte,
  }) {
    return Vanne(
      nom: nom ?? this.nom,
      estOuverte: estOuverte ?? this.estOuverte,
      id: id ?? this.id,
    );
  }

  /// Le backend envoie `etat: "ouverte" | "fermee"`.
  factory Vanne.fromJson(Map<String, dynamic> json) {
    return Vanne(
      id: json['id']?.toString(),
      nom: (json['nom'] ?? '').toString(),
      estOuverte: json['etat'] == 'ouverte',
    );
  }
}
