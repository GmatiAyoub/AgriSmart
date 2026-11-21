import 'package:flutter/foundation.dart';
import 'package:agrismart/models/meteo.dart';
import 'package:agrismart/services/meteo_service.dart';

// Les trois états d'un chargement reseau
enum EtatMeteo { chargement, succes, erreur }

class MeteoProvider extends ChangeNotifier {
  final MeteoService _service;

  MeteoProvider({MeteoService? service}) : _service = service ?? MeteoService();

  EtatMeteo _etat = EtatMeteo.chargement;
  Meteo? _meteo;
  String _erreur = '';

  EtatMeteo get etat => _etat;
  Meteo? get meteo => _meteo;
  String get erreur => _erreur;

  Future<void> charger() async {
    // TODO 1 : passer l'etat a chargement
    _etat = EtatMeteo.chargement;
    notifyListeners();

    try {
      // TODO 2 : recuperer les donnees
      _meteo = await _service.charger();
      _etat = EtatMeteo.succes;
    } on MeteoException catch (e) {
      // TODO 3 : gerer l'erreur
      _erreur = e.message;
      _etat = EtatMeteo.erreur;
    } catch (_) {
      _erreur = 'Erreur inattendue';
      _etat = EtatMeteo.erreur;
    }
    notifyListeners(); // dans tous les cas, on previent l'ecran
  }
}