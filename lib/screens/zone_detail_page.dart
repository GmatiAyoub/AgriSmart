import 'package:flutter/material.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/theme/app_theme.dart';

class ZoneDetailPage extends StatelessWidget {
 final Zone zone;
 // Noms des autres zones, pour refuser un doublon lors de la modification
 final List<String> nomsAutres;

 const ZoneDetailPage({
  super.key,
  required this.zone,
  this.nomsAutres = const [],
 });

 // TODO 1 : Ouvrir le formulaire d'édition et renvoyer le résultat
 Future<void> _modifier(BuildContext context) async {
  final nouvelle = await Navigator.push<Zone>(
   context,
   MaterialPageRoute(
    builder: (_) => ZoneFormPage(
     zone: zone,
     nomsExistants: nomsAutres,
    ),
   ),
  );

  // Si l'utilisateur annule, ou que l'écran n'existe plus
  if (nouvelle == null || !context.mounted) return;

  // Si on a une nouvelle zone, on ferme cette fiche
  // et on renvoie la zone modifiée à la page principale
  Navigator.pop(context, nouvelle);
 }

 @override
 Widget build(BuildContext context) {
  final couleur = zone.besoinIrrigation ? AppTheme.echec : AppTheme.succes;

  // Sécurité pour les noms courts (ex: "Blé")
  final longueur = zone.culture.length < 4 ? zone.culture.length : 4;
  final texte = Theme.of(context).textTheme;

  return Scaffold(
   appBar: AppBar(
    title: Text(zone.nom),
   ),
   body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
     // TODO 2 : En-tête (Avatar + Nom + Culture)
     Row(
      children: [
       CircleAvatar(
        radius: 32,
        backgroundColor: couleur.withValues(alpha: 0.2),
        child: Text(
         zone.culture.substring(0, longueur),
         style: TextStyle(color: couleur, fontSize: 18, fontWeight: FontWeight.bold),
        ),
       ),
       const SizedBox(width: 16),
       Expanded(
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Text(zone.nom, style: texte.headlineSmall),
          Text(zone.culture, style: texte.bodyLarge),
         ],
        ),
       ),
      ],
     ),
     const SizedBox(height: 32),

     // TODO 3 : Humidité en grand et barre de progression
     Center(
      child: Text(
       '${zone.humidite.toStringAsFixed(0)} %',
       style: texte.displayMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: couleur,
       ),
      ),
     ),
     const SizedBox(height: 16),
     LinearProgressIndicator(
      value: zone.humidite / 100,
      color: couleur,
      backgroundColor: couleur.withValues(alpha: 0.2),
      minHeight: 10,
     ),
     const SizedBox(height: 16),
     Center(
      child: Text(
       zone.besoinIrrigation ? "Besoin d'irrigation" : "Sol correct",
       style: TextStyle(
           color: couleur,
           fontSize: 18,
           fontWeight: FontWeight.w600
       ),
      ),
     ),
     const SizedBox(height: 32),

     // TODO 4 : Carte des détails
     Card(
      elevation: 2,
      child: Column(
       children: [
        ListTile(
         leading: const Icon(Icons.water_drop),
         title: const Text('Humidité actuelle'),
         trailing: Text('${zone.humidite.toStringAsFixed(0)} %'),
        ),
        const Divider(height: 1),
        ListTile(
         leading: const Icon(Icons.flag),
         title: const Text("Seuil d'irrigation"),
         trailing: Text('${zone.seuil.toStringAsFixed(0)} %'),
        ),
        const Divider(height: 1),
        ListTile(
         leading: Icon(
          zone.vanneOuverte ? Icons.toggle_on : Icons.toggle_off,
          color: zone.vanneOuverte ? Colors.green : Colors.grey,
         ),
         title: const Text('Vanne'),
         trailing: Text(zone.vanneOuverte ? 'Ouverte' : 'Fermée'),
        ),
       ],
      ),
     ),
     const SizedBox(height: 32),

     // Bouton pour lancer la modification
     FilledButton.icon(
      onPressed: () => _modifier(context),
      icon: const Icon(Icons.edit),
      label: const Text('Modifier cette zone'),
      style: FilledButton.styleFrom(
       padding: const EdgeInsets.symmetric(vertical: 16),
      ),
     ),
    ],
   ),
  );
 }
}