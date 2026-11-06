
class Zone {
  final String nom;
  final String culture;
  double humidite;
  final double seuil;
  final bool vanneOuverte; // Ajouté au TP2

  Zone(
      this.nom,
      this.culture,
      this.humidite,
      this.seuil, {
        this.vanneOuverte = false,
      });

  bool get besoinIrrigation => humidite < seuil;
}

// ⚠️ C'est cette fonction qui manquait !
double humiditeMoyenne(List<Zone> zones) {
  if (zones.isEmpty) return 0;
  final somme = zones.fold<double>(0, (acc, z) => acc + z.humidite);
  return somme / zones.length;
}

// Et celle-ci aussi, au cas où
String diagnostic(Zone zone) {
  return zone.besoinIrrigation ? "Besoin d'irrigation" : "Sol correct";
}