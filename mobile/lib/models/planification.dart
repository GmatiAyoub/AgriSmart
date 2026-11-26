/// Le serveur exécute les planifications chaque semaine (jours + heure de début).
/// Il n'existe donc pas de répétition « une seule fois ».
enum RepetitionIrrigation { quotidienne, hebdomadaire }

class PlanificationIrrigation {
  final String? id;
  final String? parcelleId;
  final String zoneNom;

  /// Prochaine exécution (date calculée à partir de l'heure et des jours du serveur).
  final DateTime dateHeure;
  final int dureeMinutes;
  final RepetitionIrrigation repetition;
  final bool estActive;

  PlanificationIrrigation({
    required this.zoneNom,
    required this.dateHeure,
    required this.dureeMinutes,
    this.repetition = RepetitionIrrigation.quotidienne,
    this.estActive = true,
    this.id,
    this.parcelleId,
  });

  PlanificationIrrigation copyWith({
    String? id,
    String? parcelleId,
    String? zoneNom,
    DateTime? dateHeure,
    int? dureeMinutes,
    RepetitionIrrigation? repetition,
    bool? estActive,
  }) {
    return PlanificationIrrigation(
      id: id ?? this.id,
      parcelleId: parcelleId ?? this.parcelleId,
      zoneNom: zoneNom ?? this.zoneNom,
      dateHeure: dateHeure ?? this.dateHeure,
      dureeMinutes: dureeMinutes ?? this.dureeMinutes,
      repetition: repetition ?? this.repetition,
      estActive: estActive ?? this.estActive,
    );
  }

  static String _deux(int n) => n.toString().padLeft(2, '0');

  /// Corps envoyé au backend.
  /// - quotidienne  -> tous les jours (0 = dimanche ... 6 = samedi)
  /// - hebdomadaire -> le jour de la semaine de [dateHeure]
  /// `parcelleId` n'est envoyé qu'à la création : le serveur ne permet pas de le changer.
  Map<String, dynamic> versApi({bool creation = false}) {
    final jour = dateHeure.weekday % 7; // Dart : lundi = 1 ... dimanche = 7
    return {
      if (creation) 'parcelleId': int.parse(parcelleId!),
      'nom': 'Irrigation $zoneNom',
      'heureDebut': '${_deux(dateHeure.hour)}:${_deux(dateHeure.minute)}',
      'dureeMinutes': dureeMinutes,
      'joursSemaine': repetition == RepetitionIrrigation.quotidienne
          ? [0, 1, 2, 3, 4, 5, 6]
          : [jour],
      'active': estActive,
    };
  }

  factory PlanificationIrrigation.fromJson(Map<String, dynamic> json) {
    final jours = (json['joursSemaine'] as List).map((j) => (j as num).toInt()).toList();
    final partiesHeure = (json['heureDebut'] as String).split(':');
    final heure = int.parse(partiesHeure[0]);
    final minute = int.parse(partiesHeure[1]);

    // Prochaine occurrence : aujourd'hui ou l'un des 7 jours suivants
    final maintenant = DateTime.now();
    var prochaine = DateTime(maintenant.year, maintenant.month, maintenant.day, heure, minute);
    for (var i = 0; i < 8; i++) {
      final candidate = DateTime(maintenant.year, maintenant.month, maintenant.day + i, heure, minute);
      if (jours.contains(candidate.weekday % 7) && !candidate.isBefore(maintenant)) {
        prochaine = candidate;
        break;
      }
    }

    final parcelle = json['parcelle'];

    return PlanificationIrrigation(
      id: json['id']?.toString(),
      parcelleId: json['parcelleId']?.toString(),
      zoneNom: parcelle is Map ? (parcelle['nom'] ?? '').toString() : '',
      dateHeure: prochaine,
      dureeMinutes: (json['dureeMinutes'] as num).toInt(),
      repetition: jours.length == 7 ? RepetitionIrrigation.quotidienne : RepetitionIrrigation.hebdomadaire,
      estActive: json['active'] == true,
    );
  }
}
