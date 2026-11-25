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

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'estOuverte': estOuverte,
    };
  }

  factory Vanne.fromJson(Map<String, dynamic> json) {
    return Vanne(
      nom: (json['nom'] ?? json['name'] ?? '').toString(),
      estOuverte: (json['estOuverte'] ?? json['isOpen'] ?? json['vanneOuverte'] ?? false) as bool,
      id: (json['id'] ?? json['_id'])?.toString(),
    );
  }
}
