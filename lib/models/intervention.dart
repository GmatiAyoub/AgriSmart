import 'package:agrismart/models/intrant.dart';

/// Une application de produit sur une zone, à une date donnée (traçabilité).
class Intervention {
  final String zoneNom;
  final Intrant intrant;
  final DateTime date;
  final bool culturePrevue;

  const Intervention({
    required this.zoneNom,
    required this.intrant,
    required this.date,
    this.culturePrevue = true,
  });

  DateTime get recolteAutoriseeLe =>
      date.add(Duration(days: intrant.delaiAvantRecolteJours));
}
