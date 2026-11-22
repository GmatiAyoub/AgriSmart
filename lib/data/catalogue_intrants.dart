import 'package:agrismart/models/intrant.dart';

/// Catalogue de démonstration d'intrants agricoles.
const List<Intrant> catalogueIntrants = [
  Intrant(
    code: '6191000000011',
    nom: 'NPK Universel 15-15-15',
    type: TypeIntrant.engrais,
    cultures: ['*'],
    dosage: '50 kg / ha',
    delaiAvantRecolteJours: 0,
  ),
  Intrant(
    code: '6191000000073',
    nom: 'Herbicide Céréales Select',
    type: TypeIntrant.herbicide,
    cultures: ['ble', 'orge'],
    dosage: '1.5 L / ha',
    delaiAvantRecolteJours: 21,
  ),
  Intrant(
    code: '6191000000066',
    nom: 'Fongicide Bio Copper',
    type: TypeIntrant.fongicide,
    cultures: ['fraise', 'tomate', 'poivron', 'concombre'],
    dosage: '2 kg / ha',
    delaiAvantRecolteJours: 3,
  ),
  Intrant(
    code: '6191000000042',
    nom: 'Insecticide Protection Global',
    type: TypeIntrant.insecticide,
    cultures: ['fraise', 'poivron', 'concombre', 'tomate'],
    dosage: '1 L / ha',
    delaiAvantRecolteJours: 14,
  ),
  Intrant(
    code: '6191000000088',
    nom: 'Engrais Spécial Dattiers',
    type: TypeIntrant.engrais,
    cultures: ['dattier'],
    dosage: '3 kg / pied',
    delaiAvantRecolteJours: 0,
  ),
  Intrant(
    code: '6191000000099',
    nom: 'Fongicide Oliviers anti-Oïdium',
    type: TypeIntrant.fongicide,
    cultures: ['olivier'],
    dosage: '2.5 L / ha',
    delaiAvantRecolteJours: 7,
  ),
];
