import 'package:flutter/foundation.dart';
import 'package:agrismart/models/intervention.dart';

class InterventionsProvider extends ChangeNotifier {
  final List<Intervention> _liste = [];

  List<Intervention> get toutes => List.unmodifiable(_liste);

  /// Interventions d'une zone, la plus récente en premier.
  List<Intervention> deZone(String nomZone) {
    final resultat = _liste.where((i) => i.zoneNom == nomZone).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return resultat;
  }

  void ajouter(Intervention intervention) {
    _liste.add(intervention);
    notifyListeners();
  }

  /// Date à partir de laquelle la récolte redevient possible, ou null si aucun
  /// délai d'attente n'est en cours pour cette zone.
  DateTime? recolteAutoriseeLe(String nomZone, {DateTime? maintenant}) {
    final now = maintenant ?? DateTime.now();
    DateTime? limite;
    for (final i in _liste) {
      if (i.zoneNom != nomZone) continue;
      final fin = i.recolteAutoriseeLe;
      if (fin.isAfter(now) && (limite == null || fin.isAfter(limite))) {
        limite = fin;
      }
    }
    return limite;
  }
}
