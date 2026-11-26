import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agrismart/models/vanne.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/services/api_service.dart';

/// Zones (parcelles) et vannes.
/// Le backend est la seule source de vérité : rien n'est stocké sur le téléphone.
/// Chaque action est envoyée au serveur, puis la liste est rechargée depuis le serveur.
///
/// Les actions retournent `null` si tout s'est bien passé, sinon le message d'erreur à afficher.
class ZonesProvider extends ChangeNotifier {
  // Les planifications tournent côté serveur : on se resynchronise régulièrement
  // pour voir les vannes s'ouvrir et se fermer toutes seules.
  static const Duration _intervalleActualisation = Duration(seconds: 15);

  final ApiService _api;
  final AuthProvider _auth;

  final List<Zone> _zones = [];
  String? _uid;
  Timer? _timer;
  int _generation = 0; // sert à ignorer les réponses devenues obsolètes

  bool _estEnChargement = false;
  bool _estEnLigneRest = false;
  String? _derniereErreur;
  bool _seulementAIrriguer = false;

  ZonesProvider(this._api, this._auth) {
    _auth.addListener(_surChangementUtilisateur);
    _actualiser();
  }

  // ---------- Lecture ----------

  List<Zone> get zones => List.unmodifiable(_zones);

  List<Zone> get zonesAffichees => _seulementAIrriguer
      ? List.unmodifiable(_zones.where((z) => z.besoinIrrigation))
      : List.unmodifiable(_zones);

  int get nombre => _zones.length;
  int get nombreAIrriguer => _zones.where((z) => z.besoinIrrigation).length;

  bool get seulementAIrriguer => _seulementAIrriguer;
  bool get estEnChargement => _estEnChargement;
  bool get estEnLigneRest => _estEnLigneRest;
  String? get derniereErreur => _derniereErreur;

  List<String> noms({Zone? sauf}) {
    return _zones.where((z) => sauf == null || z.id != sauf.id).map((z) => z.nom).toList();
  }

  void basculerFiltre() {
    _seulementAIrriguer = !_seulementAIrriguer;
    notifyListeners();
  }

  // ---------- Cycle de vie / utilisateur ----------

  void _surChangementUtilisateur() {
    if (_actualiser()) notifyListeners();
  }

  bool _actualiser() {
    final uid = _auth.utilisateur?.uid;
    if (uid == _uid) return false;
    _uid = uid;

    _generation++; // invalide les chargements en cours
    _timer?.cancel();
    _zones.clear();
    _derniereErreur = null;
    _estEnLigneRest = false;

    if (uid == null) {
      _estEnChargement = false;
      _api.deconnecter();
    } else {
      chargerDepuisApi();
      _timer = Timer.periodic(
        _intervalleActualisation,
            (_) => chargerDepuisApi(silencieux: true),
      );
    }
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _auth.removeListener(_surChangementUtilisateur);
    super.dispose();
  }

  // ---------- Chargement ----------

  /// Recharge les zones depuis le serveur.
  /// [silencieux] : pas d'indicateur de chargement (actualisation automatique).
  Future<void> chargerDepuisApi({bool silencieux = false}) async {
    if (_auth.utilisateur == null) return;

    final generation = ++_generation;
    if (!silencieux) {
      _estEnChargement = true;
      notifyListeners();
    }

    try {
      final zones = await _api.getZones();
      if (generation != _generation) return;
      _zones
        ..clear()
        ..addAll(zones);
      _estEnLigneRest = true;
      _derniereErreur = null;
    } on ApiException catch (e) {
      if (generation != _generation) return;
      _estEnLigneRest = false;
      _derniereErreur = e.message;
    } catch (_) {
      if (generation != _generation) return;
      _estEnLigneRest = false;
      _derniereErreur = 'Erreur lors de la synchronisation';
    } finally {
      if (generation == _generation) {
        _estEnChargement = false;
        notifyListeners();
      }
    }
  }

  /// Exécute une action sur le serveur puis recharge. Retourne le message d'erreur, ou null.
  Future<String?> _executer(Future<void> Function() action) async {
    String? erreur;
    try {
      await action();
    } on ApiException catch (e) {
      erreur = e.message;
    } catch (_) {
      erreur = 'Une erreur est survenue';
    }
    await chargerDepuisApi(silencieux: true);
    return erreur;
  }

  // ---------- Zones ----------

  Future<String?> ajouter(Zone zone) => _executer(() => _api.creerZone(zone));

  /// Modifie les champs de la parcelle (nom, culture, seuil...). Les vannes ne sont pas touchées.
  Future<String?> remplacer(Zone ancienne, Zone nouvelle) {
    final id = nouvelle.id ?? ancienne.id;
    if (id == null) return Future.value('Zone sans identifiant');
    return _executer(() => _api.modifierZone(id, nouvelle));
  }

  Future<String?> supprimer(Zone zone) {
    final id = zone.id;
    if (id == null) return Future.value('Zone sans identifiant');
    return _executer(() => _api.supprimerZone(id));
  }

  // ---------- Vannes ----------

  /// Bouton « Irriguer » : ouvre toutes les vannes de la parcelle, ou les ferme si l'une est ouverte.
  Future<String?> irriguerParcelle(Zone zone) {
    final id = zone.id;
    if (id == null) return Future.value('Zone sans identifiant');
    if (zone.vannes.isEmpty) return Future.value("Cette parcelle n'a aucune vanne");
    return _executer(() => _api.irriguer(id, !zone.auMoinsUneVanneOuverte));
  }

  Future<String?> basculerVanne(Zone zone, int vanneIndex) {
    final vanne = _vanne(zone, vanneIndex);
    if (vanne?.id == null) return Future.value('Vanne introuvable');
    return _executer(() => _api.commanderVanne(vanne!.id!, !vanne.estOuverte));
  }

  Future<String?> ajouterVanne(Zone zone, Vanne nouvelleVanne) {
    final id = zone.id;
    if (id == null) return Future.value('Zone sans identifiant');
    return _executer(() => _api.creerVanne(id, nouvelleVanne.nom));
  }

  Future<String?> modifierVanne(Zone zone, int vanneIndex, Vanne vanneModifiee) {
    final vanne = _vanne(zone, vanneIndex);
    if (vanne?.id == null) return Future.value('Vanne introuvable');
    return _executer(() => _api.renommerVanne(vanne!.id!, vanneModifiee.nom));
  }

  Future<String?> supprimerVanne(Zone zone, int vanneIndex) {
    final vanne = _vanne(zone, vanneIndex);
    if (vanne?.id == null) return Future.value('Vanne introuvable');
    return _executer(() => _api.supprimerVanne(vanne!.id!));
  }

  Vanne? _vanne(Zone zone, int index) =>
      index >= 0 && index < zone.vannes.length ? zone.vannes[index] : null;
}
