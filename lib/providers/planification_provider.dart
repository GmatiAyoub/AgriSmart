import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrismart/models/planification.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';

class PlanificationProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final AuthProvider _auth;
  ZonesProvider? _zonesProvider;

  final List<PlanificationIrrigation> _planifications = [];
  String? _uid;
  Timer? _timerExecution;

  PlanificationProvider(this._prefs, this._auth, {ZonesProvider? zonesProvider}) {
    _zonesProvider = zonesProvider;
    _auth.addListener(_surChangementUtilisateur);
    _actualiser();
    _demarrerTimerExecution();
  }

  void mettreAJourZonesProvider(ZonesProvider zonesProvider) {
    _zonesProvider = zonesProvider;
    verifierEtExecuterPlanifications();
  }

  void _demarrerTimerExecution() {
    _timerExecution?.cancel();
    _timerExecution = Timer.periodic(const Duration(seconds: 4), (_) {
      verifierEtExecuterPlanifications();
    });
  }

  List<PlanificationIrrigation> get planifications => List.unmodifiable(_planifications);

  int get nombre => _planifications.length;
  int get nombreActives => _planifications.where((p) => p.estActive).length;

  String _cle(String uid) => 'planifications_$uid';

  void _sauvegarderLocal() {
    final uid = _uid;
    if (uid == null) return;
    final texte = jsonEncode(_planifications.map((p) => p.toJson()).toList());
    _prefs.setString(_cle(uid), texte);
  }

  List<PlanificationIrrigation> _lireLocal(String uid) {
    final texte = _prefs.getString(_cle(uid));
    if (texte == null) return _jeuDeDonneesParDefaut();
    try {
      final liste = jsonDecode(texte) as List<dynamic>;
      return liste
          .map((e) => PlanificationIrrigation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _jeuDeDonneesParDefaut();
    }
  }

  bool _actualiser() {
    final uid = _auth.utilisateur?.uid;
    if (uid == _uid) return false;
    _uid = uid;
    _planifications.clear();
    if (uid != null) {
      _planifications.addAll(_lireLocal(uid));
    }
    return true;
  }

  void _surChangementUtilisateur() {
    if (_actualiser()) notifyListeners();
  }

  @override
  void dispose() {
    _timerExecution?.cancel();
    _auth.removeListener(_surChangementUtilisateur);
    super.dispose();
  }

  List<PlanificationIrrigation> _jeuDeDonneesParDefaut() {
    final maintenant = DateTime.now();
    return [
      PlanificationIrrigation(
        zoneNom: 'Parcelle Sud',
        dateHeure: maintenant.add(const Duration(minutes: 5)),
        dureeMinutes: 15,
        repetition: RepetitionIrrigation.uneFois,
        estActive: true,
      ),
      PlanificationIrrigation(
        zoneNom: 'Serre 1',
        dateHeure: maintenant.add(const Duration(hours: 1)),
        dureeMinutes: 30,
        repetition: RepetitionIrrigation.quotidienne,
        estActive: true,
      ),
    ];
  }

  /// Vérifie et déclenche automatiquement l'irrigation pour les planifications en cours
  void verifierEtExecuterPlanifications() {
    final zonesProv = _zonesProvider;
    if (zonesProv == null) return;

    final maintenant = DateTime.now();
    bool modifie = false;

    for (int i = 0; i < _planifications.length; i++) {
      final p = _planifications[i];
      if (!p.estActive) continue;

      final debut = p.dateHeure;
      final fin = p.dateHeure.add(Duration(minutes: p.dureeMinutes));

      // 1. Si nous sommes dans la plage horaire programmée (début <= maintenant < fin)
      if ((maintenant.isAfter(debut) || maintenant.isAtSameMomentAs(debut)) && maintenant.isBefore(fin)) {
        final zoneIndex = zonesProv.zones.indexWhere(
          (z) => z.nom.trim().toLowerCase() == p.zoneNom.trim().toLowerCase(),
        );

        if (zoneIndex != -1) {
          final zone = zonesProv.zones[zoneIndex];
          // Ouvrir automatiquement toutes les vannes de la parcelle
          if (!zone.auMoinsUneVanneOuverte) {
            zonesProv.irriguerParcelle(zone);
          }
        }
      }

      // 2. Si la durée d'irrigation est terminée (maintenant >= fin)
      if (maintenant.isAfter(fin) || maintenant.isAtSameMomentAs(fin)) {
        final zoneIndex = zonesProv.zones.indexWhere(
          (z) => z.nom.trim().toLowerCase() == p.zoneNom.trim().toLowerCase(),
        );

        if (zoneIndex != -1) {
          final zone = zonesProv.zones[zoneIndex];
          // Fermer les vannes de la parcelle à la fin du temps imparti
          if (zone.auMoinsUneVanneOuverte) {
            zonesProv.irriguerParcelle(zone);
          }
        }

        // Mettre à jour la répétition
        if (p.repetition == RepetitionIrrigation.uneFois) {
          _planifications[i] = p.copyWith(estActive: false);
          modifie = true;
        } else if (p.repetition == RepetitionIrrigation.quotidienne) {
          _planifications[i] = p.copyWith(dateHeure: p.dateHeure.add(const Duration(days: 1)));
          modifie = true;
        } else if (p.repetition == RepetitionIrrigation.hebdomadaire) {
          _planifications[i] = p.copyWith(dateHeure: p.dateHeure.add(const Duration(days: 7)));
          modifie = true;
        }
      }
    }

    if (modifie) {
      _sauvegarderLocal();
      notifyListeners();
    }
  }

  Future<void> ajouter(PlanificationIrrigation item) async {
    _planifications.add(item);
    _sauvegarderLocal();
    notifyListeners();
    verifierEtExecuterPlanifications();
  }

  Future<void> modifier(PlanificationIrrigation ancien, PlanificationIrrigation nouveau) async {
    final index = _planifications.indexOf(ancien);
    if (index != -1) {
      _planifications[index] = nouveau;
      _sauvegarderLocal();
      notifyListeners();
      verifierEtExecuterPlanifications();
    }
  }

  Future<void> supprimer(PlanificationIrrigation item) async {
    final zonesProv = _zonesProvider;
    if (zonesProv != null) {
      final zoneIndex = zonesProv.zones.indexWhere(
        (z) => z.nom.trim().toLowerCase() == item.zoneNom.trim().toLowerCase(),
      );
      if (zoneIndex != -1) {
        final zone = zonesProv.zones[zoneIndex];
        if (zone.auMoinsUneVanneOuverte) {
          zonesProv.irriguerParcelle(zone);
        }
      }
    }
    _planifications.remove(item);
    _sauvegarderLocal();
    notifyListeners();
  }

  Future<void> basculerEtat(PlanificationIrrigation item) async {
    final index = _planifications.indexOf(item);
    if (index == -1) return;

    final nouveauStatut = !item.estActive;
    final itemModifie = item.copyWith(estActive: nouveauStatut);
    _planifications[index] = itemModifie;
    _sauvegarderLocal();
    notifyListeners();

    final zonesProv = _zonesProvider;
    if (zonesProv != null && !nouveauStatut) {
      final zoneIndex = zonesProv.zones.indexWhere(
        (z) => z.nom.trim().toLowerCase() == item.zoneNom.trim().toLowerCase(),
      );

      if (zoneIndex != -1) {
        final zone = zonesProv.zones[zoneIndex];
        // En désactivant la planification, la parcelle passe au repos (vannes fermées)
        if (zone.auMoinsUneVanneOuverte) {
          zonesProv.irriguerParcelle(zone);
        }
      }
    }

    verifierEtExecuterPlanifications();
  }
}
