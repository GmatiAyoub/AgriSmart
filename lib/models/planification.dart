enum RepetitionIrrigation { uneFois, quotidienne, hebdomadaire }

class PlanificationIrrigation {
  final String? id;
  final String zoneNom;
  final DateTime dateHeure;
  final int dureeMinutes; // en minutes
  final RepetitionIrrigation repetition;
  final bool estActive;

  PlanificationIrrigation({
    required this.zoneNom,
    required this.dateHeure,
    required this.dureeMinutes,
    this.repetition = RepetitionIrrigation.uneFois,
    this.estActive = true,
    this.id,
  });

  PlanificationIrrigation copyWith({
    String? id,
    String? zoneNom,
    DateTime? dateHeure,
    int? dureeMinutes,
    RepetitionIrrigation? repetition,
    bool? estActive,
  }) {
    return PlanificationIrrigation(
      id: id ?? this.id,
      zoneNom: zoneNom ?? this.zoneNom,
      dateHeure: dateHeure ?? this.dateHeure,
      dureeMinutes: dureeMinutes ?? this.dureeMinutes,
      repetition: repetition ?? this.repetition,
      estActive: estActive ?? this.estActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'zoneNom': zoneNom,
      'dateHeure': dateHeure.toIso8601String(),
      'dureeMinutes': dureeMinutes,
      'repetition': repetition.name,
      'estActive': estActive,
    };
  }

  factory PlanificationIrrigation.fromJson(Map<String, dynamic> json) {
    RepetitionIrrigation rep = RepetitionIrrigation.uneFois;
    final repStr = (json['repetition'] ?? '').toString();
    if (repStr == 'quotidienne') rep = RepetitionIrrigation.quotidienne;
    if (repStr == 'hebdomadaire') rep = RepetitionIrrigation.hebdomadaire;

    return PlanificationIrrigation(
      zoneNom: (json['zoneNom'] ?? json['zone_nom'] ?? json['zone'] ?? '').toString(),
      dateHeure: DateTime.tryParse(json['dateHeure'] ?? json['date_heure'] ?? '') ?? DateTime.now(),
      dureeMinutes: (json['dureeMinutes'] ?? json['duree'] ?? 30) as int,
      repetition: rep,
      estActive: (json['estActive'] ?? json['is_active'] ?? true) as bool,
      id: (json['id'] ?? json['_id'])?.toString(),
    );
  }
}
