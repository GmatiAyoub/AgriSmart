import 'package:agrismart/models/zone.dart';
import 'package:agrismart/models/vanne.dart';

List<Zone> jeuDeDonnees() {
  return [
    Zone(
      'Parcelle Nord',
      'Tomates',
      28,
      35,
      vannes: [
        Vanne(nom: 'Vanne A1 (Goutte à goutte)', estOuverte: true),
        Vanne(nom: 'Vanne A2 (Ligne Sud)', estOuverte: false),
      ],
    ),
    Zone(
      'Parcelle Sud',
      'Oliviers',
      42,
      30,
      vannes: [
        Vanne(nom: 'Vanne B1 (Secteur Est)', estOuverte: false),
        Vanne(nom: 'Vanne B2 (Secteur Ouest)', estOuverte: false),
      ],
    ),
    Zone(
      'Serre 1',
      'Fraises',
      55,
      50,
      vannes: [
        Vanne(nom: 'Vanne S1 (Aspersion)', estOuverte: true),
        Vanne(nom: 'Vanne S2 (Micro-goutte)', estOuverte: true),
      ],
    ),
    Zone(
      'Parcelle Est',
      'Blé',
      20,
      35,
      vannes: [
        Vanne(nom: 'Vanne E1 (Canal principal)', estOuverte: false),
      ],
    ),
    Zone(
      'Parcelle Ouest',
      'Orge',
      38,
      35,
      vannes: [
        Vanne(nom: 'Vanne O1', estOuverte: false),
        Vanne(nom: 'Vanne O2', estOuverte: false),
      ],
    ),
    Zone(
      'Serre 2',
      'Poivrons',
      60,
      55,
      vannes: [
        Vanne(nom: 'Vanne Serre 2', estOuverte: true),
      ],
    ),
    Zone(
      'Verger',
      'Pommiers',
      33,
      30,
      vannes: [
        Vanne(nom: 'Vanne Verger Haut', estOuverte: false),
        Vanne(nom: 'Vanne Verger Bas', estOuverte: false),
      ],
    ),
    Zone(
      'Parcelle Centre',
      'Luzerne',
      25,
      40,
      vannes: [
        Vanne(nom: 'Vanne Centre 1', estOuverte: false),
      ],
    ),
    Zone(
      'Serre 3',
      'Concombres',
      70,
      60,
      vannes: [
        Vanne(nom: 'Vanne Serre 3A', estOuverte: true),
        Vanne(nom: 'Vanne Serre 3B', estOuverte: true),
      ],
    ),
    Zone(
      'Palmeraie',
      'Dattiers',
      45,
      40,
      vannes: [
        Vanne(nom: 'Vanne Palmeraie 1', estOuverte: false),
        Vanne(nom: 'Vanne Palmeraie 2', estOuverte: false),
      ],
    ),
  ];
}
