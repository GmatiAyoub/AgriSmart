import 'dart:async';

import 'package:agrismart/models/utilisateur.dart';
import 'package:agrismart/services/auth_service.dart';

// Variante sans Firebase : les comptes sont gardés en mémoire
// (ils disparaissent à la fermeture de l'application).
class AuthLocaleService implements AuthService {
  final Map<String, String> _comptes = {
    'demo@agrismart.tn': '123456',
  };

  final Map<String, String> _noms = {
    'demo@agrismart.tn': 'Utilisateur Demo',
  };

  final StreamController<Utilisateur?> _controller =
  StreamController<Utilisateur?>.broadcast();

  Utilisateur? _courant;

  @override
  Stream<Utilisateur?> get utilisateur async* {
    yield _courant;
    yield* _controller.stream;
  }

  void _definir(Utilisateur? u) {
    _courant = u;
    _controller.add(u);
  }

  // Connexion
  @override
  Future<void> connexion(String email, String motDePasse) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final cle = email.trim().toLowerCase();

    if (_comptes[cle] != motDePasse) {
      throw const AuthException('Email ou mot de passe incorrect');
    }

    _definir(
      Utilisateur(
        uid: cle,
        email: cle,
        nom: _noms[cle] ?? 'Utilisateur',
      ),
    );
  }

  // Inscription
  @override
  Future<void> inscription(
      String email,
      String motDePasse,
      String nom,
      ) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final cle = email.trim().toLowerCase();

    if (_comptes.containsKey(cle)) {
      throw const AuthException(
        'Un compte existe déjà avec cet email',
      );
    }

    _comptes[cle] = motDePasse;
    _noms[cle] = nom.trim();

    _definir(
      Utilisateur(
        uid: cle,
        email: cle,
        nom: nom.trim(),
      ),
    );
  }

  // Réinitialisation du mot de passe
  @override
  Future<void> reinitialiserMotDePasse(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  // Déconnexion
  @override
  Future<void> deconnexion() async {
    _definir(null);
  }

  // Suppression du compte
  @override
  Future<void> supprimerCompte() async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (_courant == null) {
      throw const AuthException('Aucun utilisateur connecté');
    }

    final cle = _courant!.email;

    _comptes.remove(cle);
    _noms.remove(cle);

    _definir(null);
  }
}