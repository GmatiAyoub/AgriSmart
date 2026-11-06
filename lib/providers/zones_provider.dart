import 'package:flutter/foundation.dart';
import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/models/zone.dart';

class ZonesProvider extends ChangeNotifier {
  final List<Zone> _zones = jeuDeDonnees();

  // 🆕 Exercice 1 : Variable pour le filtre
  bool _seulementAIrriguer = false;
  bool get seulementAIrriguer => _seulementAIrriguer;

  // Toutes les zones (lecture seule)
  List<Zone> get zones => List.unmodifiable(_zones);

  // 🆕 Exercice 1 : Le getter qui filtre selon le bouton
  List<Zone> get zonesAffichees => _seulementAIrriguer
      ? List.unmodifiable(_zones.where((z) => z.besoinIrrigation))
      : List.unmodifiable(_zones);

  int get nombre => _zones.length;
  int get nombreAIrriguer => _zones.where((z) => z.besoinIrrigation).length;

  List<String> noms({Zone? sauf}) {
    return _zones.where((z) => z != sauf).map((z) => z.nom).toList();
  }

  // 🆕 Exercice 1 : Méthode pour basculer le filtre
  void basculerFiltre() {
    _seulementAIrriguer = !_seulementAIrriguer;
    notifyListeners();
  }

  void modifierHumidite(Zone zone, double delta) {
    zone.humidite = (zone.humidite + delta).clamp(0, 100).toDouble();
    notifyListeners();
  }

  void ajouter(Zone zone) {
    _zones.add(zone);
    notifyListeners();
  }

  void remplacer(Zone ancienne, Zone nouvelle) {
    final index = _zones.indexOf(ancienne);
    if (index != -1) {
      _zones[index] = nouvelle;
      notifyListeners();
    }
  }

  void supprimer(Zone zone) {
    _zones.remove(zone);
    notifyListeners();
  }
}