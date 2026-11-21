enum EtatVisuel { sain, anomalie, indetermine }

enum NiveauConfiance { faible, moyen, eleve }

/// Résultat préliminaire d'analyse d'une photo de plante.
class DiagnosticPlante {
  /// Culture détectée automatiquement ou indiquée par l'utilisateur (null = non identifiée).
  final String? culture;
  final bool cultureIndiquee;
  final EtatVisuel etat;

  /// Estimation entre 0 et 1 (plafonnée : une photo ne suffit jamais à certifier).
  final double confiance;

  /// Part du feuillage qui présente des taches / décolorations (0..1).
  final double partieAnomalie;

  /// Part de l'image occupée par du feuillage (0..1).
  final double couvertureFeuillage;

  const DiagnosticPlante({
    required this.culture,
    required this.cultureIndiquee,
    required this.etat,
    required this.confiance,
    required this.partieAnomalie,
    required this.couvertureFeuillage,
  });

  NiveauConfiance get niveau {
    if (confiance >= 0.65) return NiveauConfiance.eleve;
    if (confiance >= 0.4) return NiveauConfiance.moyen;
    return NiveauConfiance.faible;
  }
}
