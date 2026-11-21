import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TraductionException implements Exception {
  final String message;
  const TraductionException(this.message);
}

class TraductionService {
  final _modelManager = OnDeviceTranslatorModelManager();

  /// Vérifie si le modèle pour une langue donnée est déjà installé.
  Future<bool> estModeleInstalle(TranslateLanguage langue) async {
    try {
      return await _modelManager.isModelDownloaded(langue.bcpCode);
    } catch (e) {
      if (e is MissingPluginException) {
        throw const TraductionException(
          'ML Kit est disponible uniquement sur appareil mobile (Android / iOS).',
        );
      }
      return false;
    }
  }

  /// Télécharge explicitement un modèle. À appeler idéalement en Wi-Fi.
  Future<void> telechargerModele(TranslateLanguage langue) async {
    try {
      final succes = await _modelManager.downloadModel(langue.bcpCode);
      if (!succes) {
        throw const TraductionException('Impossible de télécharger le modèle de langue. Vérifiez votre connexion Internet.');
      }
    } catch (e) {
      if (e is TraductionException) rethrow;
      if (e is MissingPluginException) {
        throw const TraductionException(
          'ML Kit est disponible uniquement sur appareil mobile (Android / iOS).',
        );
      }
      throw TraductionException('Erreur lors du téléchargement du modèle : $e');
    }
  }

  /// Traduit un texte. Assume que le modèle est déjà téléchargé.
  Future<String> traduire(String texte, TranslateLanguage source, TranslateLanguage cible) async {
    final traducteur = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: cible,
    );

    try {
      final resultat = await traducteur.translateText(texte);
      return resultat;
    } catch (e) {
      if (e is MissingPluginException) {
        throw const TraductionException(
          'ML Kit est disponible uniquement sur appareil mobile (Android / iOS).',
        );
      }
      throw const TraductionException('La traduction a échoué. Vérifiez que le modèle est installé et que votre appareil est connecté.');
    } finally {
      traducteur.close();
    }
  }
}