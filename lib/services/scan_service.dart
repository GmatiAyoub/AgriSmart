import 'package:agrismart/data/catalogue_intrants.dart';
import 'package:agrismart/models/intrant.dart';

/// Texte en minuscules, sans accents ni espaces autour (pour comparer des cultures).
String normaliserTexte(String texte) {
  const avec = 'àâäéèêëîïôöùûüç';
  const sans = 'aaaeeeeiioouuuc';
  final buffer = StringBuffer();
  for (final c in texte.trim().toLowerCase().split('')) {
    final i = avec.indexOf(c);
    buffer.write(i == -1 ? c : sans[i]);
  }
  return buffer.toString();
}

/// Contenu des QR codes de zone : `agrismart://zone/<nom encodé>`.
class CodeZone {
  static const String prefixe = 'agrismart://zone/';

  static String encoder(String nomZone) => '$prefixe${Uri.encodeComponent(nomZone)}';

  /// Retourne le nom de la zone, ou null si [contenu] n'est pas un QR de zone.
  static String? decoder(String contenu) {
    final texte = contenu.trim();
    if (!texte.startsWith(prefixe)) return null;
    final brut = texte.substring(prefixe.length);
    if (brut.isEmpty) return null;
    try {
      return Uri.decodeComponent(brut);
    } catch (_) {
      return null;
    }
  }
}

/// Le produit est-il prévu pour cette culture ?
bool intrantConvientA(Intrant intrant, String culture) {
  final c = normaliserTexte(culture);
  return intrant.cultures.any((x) => x == '*' || c.startsWith(x));
}

Intrant? trouverIntrant(String code) {
  final propre = code.trim();
  for (final i in catalogueIntrants) {
    if (i.code == propre) return i;
  }
  return null;
}

String formaterDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
