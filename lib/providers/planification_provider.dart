import 'package:flutter/foundation.dart';
import 'package:agrismart/models/planification.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/services/api_service.dart';

/// Planifications d'irrigation.
/// Elles sont stock├®es ET ex├®cut├®es par le backend (m├¬me app ferm├®e) : l'app ne fait qu'afficher
/// et modifier. Les actions retournent `null` si tout va bien, sinon le message d'erreur.
class PlanificationProvider extends ChangeNotifier {
  final ApiService _api;
  final AuthProvider _auth;
  ZonesProvider? _zonesProvider;

  final List<PlanificationIrrigation> _planifications = [];
  String? _uid;
  int _generation = 0;
  bool _estEnChargement = false;
  String? _derniereErreur;

  PlanificationProvider(this._api, this._auth, {ZonesProvider? zonesProvider}) {
    _zonesProvider = zonesProvider;
    _auth.addListener(_surChangementUtilisateur);
    _actualiser();
  }

  void mettreAJourZonesProvider(ZonesProvider zonesProvider) {
    _zonesProvider = zonesProvider;
  }

  List<PlanificationIrrigation> get planifications => List.unmodifiable(_planifications);
  int get nombre => _planifications.length;
  int get nombreActives => _planifications.where((p) => p.estActive).length;
  bool get estEnChargement => _estEnChargement;
  String? get derniereErreur => _derniereErreur;

  // ---------- Cycle de vie / utilisateur ----------

  void _surChangementUtilisateur() {
    if (_actualiser()) notifyListeners();
  }

  bool _actualiser() {
    final uid = _auth.utilisateur?.uid;
    if (uid == _uid) return false;
    _uid = uid;

    _generation++;
    _planifications.clear();
    _derniereErreur = null;
    _estEnChargement = false;

    if (uid != null) charger();
    return true;
  }

  @override
  void dispose() {
    _auth.removeListener(_surChangementUtilisateur);
    super.dispose();
  }

  // ---------- Chargement ----------

  Future<void> charger({bool silencieux = false}) async {
    if (_auth.utilisateur == null) return;

    final generation = ++_generation;
    if (!silencieux) {
      _estEnChargement = true;
      notifyListeners();
    }

    try {
      final liste = await _api.getPlanifications();
      if (generation != _generation) return;
      _planifications
        ..clear()
        ..addAll(liste);
      _derniereErreur = null;
    } on ApiException catch (e) {
      if (generation != _generation) return;
      _derniereErreur = e.message;
    } catch (_) {
      if (generation != _generation) return;
      _derniereErreur = 'Erreur lors du chargement des planifications';
    } finally {
      if (generation == _generation) {
        _estEnChargement = false;
        notifyListeners();
      }
    }
  }

  /// Ex├®cute une action, puis recharge les planifications ET les zones
  /// (d├®sactiver ou supprimer une planification en cours ferme les vannes c├┤t├® serveur).
  Future<String?> _executer(Future<void> Function() action) async {
    String? erreur;
    try {
      await action();
    } on ApiException catch (e) {
      erreur = e.message;
    } catch (_) {
      erreur = 'Une erreur est survenue';
    }
    await Future.wait([
      charger(silencieux: true),
      _zonesProvider?.chargerDepuisApi(silencieux: true) ?? Future.value(),
    ]);
    return erreur;
  }

  /// Retrouve l'id de la parcelle ├á partir de son nom (choisi dans le formulaire).
  String _idParcelle(String zoneNom) {
    final zones = _zonesProvider?.zones ?? const [];
    for (final z in zones) {
      if (z.id != null && z.nom.trim().toLowerCase() == zoneNom.trim().toLowerCase()) {
        return z.id!;
      }
    }
    throw ApiException('Parcelle introuvable');
  }

  // ---------- Actions ----------

  Future<String?> ajouter(PlanificationIrrigation item) {
    return _executer(() async {
      await _api.creerPlanification(item.copyWith(parcelleId: _idParcelle(item.zoneNom)));
    });
  }

  Future<String?> modifier(PlanificationIrrigation ancien, PlanificationIrrigation nouveau) {
    final id = ancien.id;
    if (id == null) return Future.value('Planification sans identifiant');

    return _executer(() async {
      final nouvelleParcelle = _idParcelle(nouveau.zoneNom);
      if (nouvelleParcelle == ancien.parcelleId) {
        await _api.modifierPlanification(id, nouveau);
      } else {
        // Le serveur ne permet pas de changer de parcelle : on cr├®e la nouvelle, puis on supprime l'ancienne
        await _api.creerPlanification(nouveau.copyWith(parcelleId: nouvelleParcelle));
        await _api.supprimerPlanification(id);
      }
    });
  }

  Future<String?> supprimer(PlanificationIrrigation item) {
    final id = item.id;
    if (id == null) return Future.value('Planification sans identifiant');
    return _executer(() => _api.supprimerPlanification(id));
  }

  Future<String?> basculerEtat(PlanificationIrrigation item) {
    final id = item.id;
    if (id == null) return Future.value('Planification sans identifiant');
    return _executer(() => _api.activerPlanification(id, !item.estActive));
  }
}
