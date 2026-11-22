import 'package:flutter_test/flutter_test.dart';
import 'package:agrismart/models/intervention.dart';
import 'package:agrismart/providers/interventions_provider.dart';
import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/services/scan_service.dart';

void main() {
  group('QR de zone', () {
    test('aller-retour avec accents et espaces', () {
      for (final z in jeuDeDonnees()) {
        expect(CodeZone.decoder(CodeZone.encoder(z.nom)), z.nom);
      }
    });

    test('un code-barres produit n\'est pas un QR de zone', () {
      expect(CodeZone.decoder('6191000000011'), isNull);
      expect(CodeZone.decoder('agrismart://zone/'), isNull);
    });
  });

  group('Compatibilité produit / culture', () {
    final herbicide = trouverIntrant('6191000000073')!;
    final npk = trouverIntrant('6191000000011')!;

    test('herbicide céréales : blé et orge oui, tomates non', () {
      expect(intrantConvientA(herbicide, 'Blé'), isTrue);
      expect(intrantConvientA(herbicide, 'Orge'), isTrue);
      expect(intrantConvientA(herbicide, 'Tomates'), isFalse);
    });

    test('NPK universel', () {
      expect(intrantConvientA(npk, 'Dattiers'), isTrue);
    });

    test('produit inconnu', () {
      expect(trouverIntrant('0000000000000'), isNull);
    });
  });

  group('Délai avant récolte', () {
    test('la date la plus lointaine est retenue, puis le délai expire', () {
      final p = InterventionsProvider();
      final debut = DateTime(2026, 6, 1);
      p.ajouter(Intervention(zoneNom: 'Serre 1', intrant: trouverIntrant('6191000000066')!, date: debut)); // 3 j
      p.ajouter(Intervention(zoneNom: 'Serre 1', intrant: trouverIntrant('6191000000042')!, date: debut)); // 14 j

      expect(p.recolteAutoriseeLe('Serre 1', maintenant: DateTime(2026, 6, 5)), DateTime(2026, 6, 15));
      expect(p.recolteAutoriseeLe('Serre 1', maintenant: DateTime(2026, 6, 20)), isNull);
      expect(p.recolteAutoriseeLe('Serre 2', maintenant: DateTime(2026, 6, 5)), isNull);
    });
  });
}
