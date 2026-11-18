import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agrismart/models/utilisateur.dart';
import 'package:agrismart/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  late final StreamSubscription<Utilisateur?> _abonnement;

  Utilisateur? _utilisateur;
  bool _initialise = false;
  bool _occupe = false;
  String? _erreur;

  AuthProvider(this._service) {
    _abonnement = _service.utilisateur.listen((u) {
      _utilisateur = u;
      _initialise = true;
      notifyListeners();
    });
  }

  Utilisateur? get utilisateur => _utilisateur;
  bool get initialise => _initialise;
  bool get occupe => _occupe;

  // ⚠️ CORRECTION 1 : Ajout du "?" pour dire que l'erreur peut être nulle
  String? get erreur => _erreur;

  bool get connecte => _utilisateur != null;

  Future<bool> connexion(String email, String motDePasse) {
    return _executer(() => _service.connexion(email, motDePasse));
  }

  Future<bool> inscription(String email, String motDePasse) {
    return _executer(() => _service.inscription(email, motDePasse));
  }

  Future<bool> reinitialiserMotDePasse(String email) {
    return _executer(() => _service.reinitialiserMotDePasse(email));
  }

  // ⚠️ CORRECTION 2 : _service.deconnexion() renvoie Future<void>, 
  // on l'enveloppe pour renvoyer un Future<bool> (true en cas de succès)
  Future<bool> deconnexion() async {
    await _service.deconnexion();
    return true;
  }

  void effacerErreur() {
    if (_erreur == null) return;
    _erreur = null;
    notifyListeners();
  }

  // ⚠️ CORRECTION 3 : L'opération passée en paramètre renvoie Future<void> 
  // (et non Future<bool>, comme indiqué par erreur dans le PDF)
  Future<bool> _executer(Future<void> Function() operation) async {
    _occupe = true;
    _erreur = null;
    notifyListeners();

    var succes = false;
    try {
      await operation();
      succes = true;
    } on AuthException catch (e) {
      _erreur = e.message;
    } catch (_) {
      _erreur = 'Une erreur est survenue';
    }

    _occupe = false;
    notifyListeners();
    return succes;
  }

  @override
  void dispose() {
    _abonnement.cancel();
    super.dispose();
  }
}