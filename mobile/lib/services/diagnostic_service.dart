import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image/image.dart' as img;
import 'package:agrismart/models/diagnostic_plante.dart';

/// Analyse préliminaire d'une photo de plante, 100 % sur l'appareil :
/// - culture : étiquetage d'image ML Kit (Android / iOS uniquement) ou choix de l'utilisateur ;
/// - état visuel : proportion de pixels jaunes/bruns (taches, décoloration) dans le feuillage.
/// Ce n'est PAS un diagnostic médical végétal : le résultat reste une aide à l'observation.
class DiagnosticService {
  // Correspondance libellé ML Kit (anglais) -> culture affichée.
  static const Map<String, String> _cultures = {
    'tomato': 'Tomate',
    'olive': 'Olivier',
    'strawberry': 'Fraisier',
    'wheat': 'Blé',
    'barley': 'Orge',
    'bell pepper': 'Poivron',
    'pepper': 'Poivron',
    'capsicum': 'Poivron',
    'apple': 'Pommier',
    'cucumber': 'Concombre',
    'date palm': 'Palmier dattier',
    'alfalfa': 'Luzerne',
  };

  Future<DiagnosticPlante> analyser(File photo, {String? cultureIndiquee}) async {
    final octets = await photo.readAsBytes();

    // Calcul lourd dans un isolate pour ne pas bloquer l'interface.
    final stats = await compute(_analyserCouleurs, octets);
    final couverture = stats[0];
    final partieAnomalie = stats[1];

    final culture = cultureIndiquee ?? await _detecterCulture(photo);

    // Qualité de la photo : plus il y a de feuillage visible, plus l'analyse est fiable.
    final qualite = (couverture / 0.4).clamp(0.5, 1.0);

    EtatVisuel etat;
    double confiance;

    if (couverture < 0.12) {
      etat = EtatVisuel.indetermine;
      confiance = 0.2;
    } else {
      const seuil = 0.08;
      etat = partieAnomalie >= seuil ? EtatVisuel.anomalie : EtatVisuel.sain;
      // Plus on est loin du seuil de décision, plus l'estimation est nette.
      final nettete = ((partieAnomalie - seuil).abs() / seuil).clamp(0.0, 1.0);
      confiance = math.min(0.8, (0.35 + 0.45 * nettete) * qualite);
    }

    return DiagnosticPlante(
      culture: culture,
      cultureIndiquee: cultureIndiquee != null,
      etat: etat,
      confiance: confiance,
      partieAnomalie: partieAnomalie,
      couvertureFeuillage: couverture,
    );
  }

  Future<String?> _detecterCulture(File photo) async {
    ImageLabeler? etiqueteur;
    try {
      etiqueteur = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.4),
      );
      final etiquettes = await etiqueteur.processImage(InputImage.fromFile(photo));
      for (final e in etiquettes) {
        final nom = e.label.toLowerCase();
        for (final entree in _cultures.entries) {
          if (nom.contains(entree.key)) return entree.value;
        }
      }
    } catch (_) {
      // ML Kit indisponible (ex. Windows) ou erreur : culture non identifiée.
    } finally {
      await etiqueteur?.close();
    }
    return null;
  }
}

/// Retourne [couvertureFeuillage, partieAnomalie] (valeurs entre 0 et 1).
/// Fonction de premier niveau : requise par `compute`.
List<double> _analyserCouleurs(Uint8List octets) {
  final decode = img.decodeImage(octets);
  if (decode == null) return [0, 0];

  final p = img.copyResize(decode, width: 120);
  var vert = 0;
  var anomalie = 0;
  final total = p.width * p.height;

  for (var y = 0; y < p.height; y++) {
    for (var x = 0; x < p.width; x++) {
      final px = p.getPixel(x, y);
      final hsv = _versHsv(px.r.toDouble(), px.g.toDouble(), px.b.toDouble());
      final h = hsv[0], s = hsv[1], v = hsv[2];

      // Fond neutre, ombres, blanc : ignorés.
      if (v < 0.12 || s < 0.15) continue;

      if (h >= 70 && h <= 170 && s >= 0.2) {
        vert++; // feuillage sain
      } else if (h >= 20 && h < 70 && s >= 0.25 && v >= 0.15) {
        anomalie++; // jaune / brun : taches, décoloration, nécrose
      }
      // Rouge / orange (fruits, fleurs) : ignorés.
    }
  }

  final feuillage = vert + anomalie;
  final couverture = total == 0 ? 0.0 : feuillage / total;
  final partie = feuillage == 0 ? 0.0 : anomalie / feuillage;
  return [couverture, partie];
}

/// RVB (0..255) -> [teinte 0..360, saturation 0..1, valeur 0..1]
List<double> _versHsv(double r, double g, double b) {
  r /= 255;
  g /= 255;
  b /= 255;
  final maxi = math.max(r, math.max(g, b));
  final mini = math.min(r, math.min(g, b));
  final delta = maxi - mini;

  double h = 0;
  if (delta != 0) {
    if (maxi == r) {
      h = 60 * (((g - b) / delta) % 6);
    } else if (maxi == g) {
      h = 60 * (((b - r) / delta) + 2);
    } else {
      h = 60 * (((r - g) / delta) + 4);
    }
  }
  if (h < 0) h += 360;
  final s = maxi == 0 ? 0.0 : delta / maxi;
  return [h, s, maxi];
}
