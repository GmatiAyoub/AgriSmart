import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrismart/config.dart';
import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/models/vanne.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/services/api_service.dart';

class ZonesProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final AuthProvider _auth;
  final ApiService _apiService;

  final List<Zone> _zones = [];
  String? _uid; // utilisateur dont on affiche les zones

  bool _estEnChargement = false;
  String? _derniereErreur;
  bool _estEnLigneRest = false;

  ZonesProvider(this._prefs, this._auth, {ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _auth.addListener(_surChangementUtilisateur);
    _actualiser(); // charge d'abord les zones locales puis tente la synchro REST
  }

  // États d'affichage et synchro REST
  bool _seulementAIrriguer = false;
  bool get seulementAIrriguer => _seulementAIrriguer;
  bool get estEnChargement => _estEnChargement;
  String? get derniereErreur => _derniereErreur;
  bool get estEnLigneRest => _estEnLigneRest;

  // Toutes les zones (lecture seule)
  List<Zone> get zones => List.unmodifiable(_zones);

  List<Zone> get zonesAffichees => _seulementAIrriguer
      ? List.unmodifiable(_zones.where((z) => z.besoinIrrigation))
      : List.unmodifiable(_zones);

  int get nombre => _zones.length;
  int get nombreAIrriguer => _zones.where((z) => z.besoinIrrigation).length;

  List<String> noms({Zone? sauf}) {
    return _zones.where((z) => z != sauf).map((z) => z.nom).toList();
  }

  void basculerFiltre() {
    _seulementAIrriguer = !_seulementAIrriguer;
    notifyListeners();
  }

  // ---------- Stockage local et synchronisation REST ----------

  String _cle(String uid) => 'zones_$uid';

  List<Zone> _lireLocal(String uid) {
    final texte = _prefs.getString(_cle(uid));
    if (texte == null) return jeuDeDonnees();
    try {
      final liste = jsonDecode(texte) as List<dynamic>;
      return liste
          .map((e) => Zone.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return jeuDeDonnees();
    }
  }

  void _sauvegarderLocal() {
    final uid = _uid;
    if (uid == null) return;
    final texte = jsonEncode(_zones.map((z) => z.toJson()).toList());
    _prefs.setString(_cle(uid), texte);
  }

  /// Charge les zones depuis l'API REST Node.js [GET /api/zones]
  Future<void> chargerDepuisApi() async {
    if (!utiliserBackendRest) return;

    _estEnChargement = true;
    _derniereErreur = null;
    notifyListeners();

    try {
      final zonesApi = await _apiService.getZones();
      if (zonesApi.isNotEmpty) {
        _zones.clear();
        _zones.addAll(zonesApi);
        _estEnLigneRest = true;
        _sauvegarderLocal();
      }
    } on ApiException catch (e) {
      _derniereErreur = e.message;
      _estEnLigneRest = false;
    } catch (e) {
      _derniereErreur = 'Erreur lors de la synchronisation: $e';
      _estEnLigneRest = false;
    } finally {
      _estEnChargement = false;
      notifyListeners();
    }
  }

  bool _actualiser() {
    final uid = _auth.utilisateur?.uid;
    if (uid == _uid) return false;
    _uid = uid;
    _zones.clear();
    if (uid != null) {
      _zones.addAll(_lireLocal(uid));
      chargerDepuisApi();
    }
    return true;
  }

  void _surChangementUtilisateur() {
    if (_actualiser()) notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_surChangementUtilisateur);
    super.dispose();
  }

  // ---------- Actions CRUD & Gestion des Vannes ----------

  /// Ouvre ou ferme toutes les vannes d'une parcelle (Bouton "Irriguer")
  Future<void> irriguerParcelle(Zone zone) async {
    final index = _zones.indexOf(zone);
    if (index == -1) return;

    final nouvelleValeur = !zone.auMoinsUneVanneOuverte;
    final nouvellesVannes = zone.vannes
        .map((v) => v.copyWith(estOuverte: nouvelleValeur))
        .toList();

    final zoneModifiee = zone.copyWith(vannes: nouvellesVannes);
    _zones[index] = zoneModifiee;
    _sauvegarderLocal();
    notifyListeners();

    if (utiliserBackendRest && zone.id != null) {
      try {
        final reponse = await _apiService.modifierZone(zone.id!, zoneModifiee);
        _zones[index] = reponse;
        _sauvegarderLocal();
        notifyListeners();
      } catch (e) {
        _derniereErreur = e.toString();
      }
    }
  }

  /// Bascule l'état d'une vanne spécifique dans une parcelle
  Future<void> basculerVanne(Zone zone, int vanneIndex) async {
    final index = _zones.indexOf(zone);
    if (index == -1 || vanneIndex < 0 || vanneIndex >= zone.vannes.length) return;

    final v = zone.vannes[vanneIndex];
    final vannesModifiees = List<Vanne>.from(zone.vannes);
    vannesModifiees[vanneIndex] = v.copyWith(estOuverte: !v.estOuverte);

    final zoneModifiee = zone.copyWith(vannes: vannesModifiees);
    _zones[index] = zoneModifiee;
    _sauvegarderLocal();
    notifyListeners();

    if (utiliserBackendRest && zone.id != null) {
      try {
        final reponse = await _apiService.modifierZone(zone.id!, zoneModifiee);
        _zones[index] = reponse;
        _sauvegarderLocal();
        notifyListeners();
      } catch (e) {
        _derniereErreur = e.toString();
      }
    }
  }

  /// Ajoute une nouvelle vanne dans une zone
  Future<void> ajouterVanne(Zone zone, Vanne nouvelleVanne) async {
    final index = _zones.indexOf(zone);
    if (index == -1) return;

    final vannesModifiees = List<Vanne>.from(zone.vannes)..add(nouvelleVanne);
    final zoneModifiee = zone.copyWith(vannes: vannesModifiees);
    _zones[index] = zoneModifiee;
    _sauvegarderLocal();
    notifyListeners();

    if (utiliserBackendRest && zone.id != null) {
      try {
        final reponse = await _apiService.modifierZone(zone.id!, zoneModifiee);
        _zones[index] = reponse;
        _sauvegarderLocal();
        notifyListeners();
      } catch (e) {
        _derniereErreur = e.toString();
      }
    }
  }

  /// Modifie une vanne existante dans une zone
  Future<void> modifierVanne(Zone zone, int vanneIndex, Vanne vanneModifiee) async {
    final index = _zones.indexOf(zone);
    if (index == -1 || vanneIndex < 0 || vanneIndex >= zone.vannes.length) return;

    final vannesModifiees = List<Vanne>.from(zone.vannes);
    vannesModifiees[vanneIndex] = vanneModifiee;

    final zoneModifiee = zone.copyWith(vannes: vannesModifiees);
    _zones[index] = zoneModifiee;
    _sauvegarderLocal();
    notifyListeners();

    if (utiliserBackendRest && zone.id != null) {
      try {
        final reponse = await _apiService.modifierZone(zone.id!, zoneModifiee);
        _zones[index] = reponse;
        _sauvegarderLocal();
        notifyListeners();
      } catch (e) {
        _derniereErreur = e.toString();
      }
    }
  }

  /// Supprime une vanne d'une zone
  Future<void> supprimerVanne(Zone zone, int vanneIndex) async {
    final index = _zones.indexOf(zone);
    if (index == -1 || vanneIndex < 0 || vanneIndex >= zone.vannes.length) return;

    final vannesModifiees = List<Vanne>.from(zone.vannes)..removeAt(vanneIndex);
    final zoneModifiee = zone.copyWith(vannes: vannesModifiees);
    _zones[index] = zoneModifiee;
    _sauvegarderLocal();
    notifyListeners();

    if (utiliserBackendRest && zone.id != null) {
      try {
        final reponse = await _apiService.modifierZone(zone.id!, zoneModifiee);
        _zones[index] = reponse;
        _sauvegarderLocal();
        notifyListeners();
      } catch (e) {
        _derniereErreur = e.toString();
      }
    }
  }

  /// Modifie l'humidité d'une zone [PATCH /api/zones/:id]
  Future<void> modifierHumidite(Zone zone, double delta) async {
    final index = _zones.indexOf(zone);
    if (index == -1) return;

    final nouvelleHumidite = (zone.humidite + delta).clamp(0, 100).toDouble();
    zone.humidite = nouvelleHumidite;
    _sauvegarderLocal();
    notifyListeners();

    if (utiliserBackendRest && zone.id != null) {
      try {
        await _apiService.patchZone(zone.id!, {'humidite': nouvelleHumidite});
      } catch (e) {
        _derniereErreur = e.toString();
      }
    }
  }

  /// Ajoute une nouvelle zone [POST /api/zones]
  Future<void> ajouter(Zone zone) async {
    _zones.add(zone);
    _sauvegarderLocal();
    notifyListeners();

    if (utiliserBackendRest) {
      try {
        final zoneCreee = await _apiService.ajouterZone(zone);
        final index = _zones.indexOf(zone);
        if (index != -1) {
          _zones[index] = zoneCreee;
          _sauvegarderLocal();
          notifyListeners();
        }
      } catch (e) {
        _derniereErreur = e.toString();
      }
    }
  }

  /// Remplace/Modifie une zone [PUT /api/zones/:id]
  Future<void> remplacer(Zone ancienne, Zone nouvelle) async {
    final index = _zones.indexOf(ancienne);
    if (index != -1) {
      _zones[index] = nouvelle;
      _sauvegarderLocal();
      notifyListeners();

      if (utiliserBackendRest && (nouvelle.id != null || ancienne.id != null)) {
        final id = nouvelle.id ?? ancienne.id!;
        try {
          final reponse = await _apiService.modifierZone(id, nouvelle);
          _zones[index] = reponse;
          _sauvegarderLocal();
          notifyListeners();
        } catch (e) {
          _derniereErreur = e.toString();
        }
      }
    }
  }

  /// Supprime une zone [DELETE /api/zones/:id]
  Future<void> supprimer(Zone zone) async {
    final id = zone.id;
    _zones.remove(zone);
    _sauvegarderLocal();
    notifyListeners();

    if (utiliserBackendRest && id != null) {
      try {
        await _apiService.supprimerZone(id);
      } catch (e) {
        _derniereErreur = e.toString();
      }
    }
  }
}
