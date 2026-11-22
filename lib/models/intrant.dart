enum TypeIntrant { engrais, fongicide, insecticide, herbicide }

/// Produit agricole (engrais, traitement) identifié par son code-barres.
class Intrant {
  final String code;
  final String nom;
  final TypeIntrant type;

  /// Cultures pour lesquelles le produit est prévu (radicaux sans accent,
  /// en minuscules : 'tomate', 'ble'...). '*' = toutes les cultures.
  final List<String> cultures;
  final String dosage;

  /// Délai à respecter entre l'application et la récolte (0 = aucun).
  final int delaiAvantRecolteJours;

  const Intrant({
    required this.code,
    required this.nom,
    required this.type,
    required this.cultures,
    required this.dosage,
    required this.delaiAvantRecolteJours,
  });
}
