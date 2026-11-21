import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/theme/app_theme.dart';

class ZoneDetailPage extends StatelessWidget {
 final Zone zone;
 final List<String> nomsAutres;

 const ZoneDetailPage({
  super.key,
  required this.zone,
  this.nomsAutres = const [],
 });

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

  if (nouvelle == null || !context.mounted) return;
  Navigator.pop(context, nouvelle);
 }

 @override
 Widget build(BuildContext context) {
  final traduction = context.watch<TraductionProvider>();
  final couleur = zone.besoinIrrigation ? AppTheme.echec : AppTheme.succes;
  final longueur = zone.culture.length < 4 ? zone.culture.length : 4;
  final texte = Theme.of(context).textTheme;

  return Scaffold(
   appBar: AppBar(
    title: Text(zone.nom),
   ),
   body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
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
       zone.besoinIrrigation ? traduction.tr('besoinIrrigation') : traduction.tr('solCorrect'),
       style: TextStyle(
           color: couleur,
           fontSize: 18,
           fontWeight: FontWeight.w600
       ),
      ),
     ),
     const SizedBox(height: 32),

     Card(
      elevation: 2,
      child: Column(
       children: [
        ListTile(
         leading: const Icon(Icons.water_drop),
         title: Text(traduction.tr('humActuelle')),
         trailing: Text('${zone.humidite.toStringAsFixed(0)} %'),
        ),
        const Divider(height: 1),
        ListTile(
         leading: const Icon(Icons.flag),
         title: Text(traduction.tr('seuilIrrigation')),
         trailing: Text('${zone.seuil.toStringAsFixed(0)} %'),
        ),
        const Divider(height: 1),
        ListTile(
         leading: Icon(
          zone.vanneOuverte ? Icons.toggle_on : Icons.toggle_off,
          color: zone.vanneOuverte ? Colors.green : Colors.grey,
         ),
         title: Text(traduction.tr('vanne')),
         trailing: Text(zone.vanneOuverte ? traduction.tr('ouverte') : traduction.tr('fermee')),
        ),
       ],
      ),
     ),
     const SizedBox(height: 32),

     FilledButton.icon(
      onPressed: () => _modifier(context),
      icon: const Icon(Icons.edit),
      label: Text(traduction.tr('modifierCetteZone')),
      style: FilledButton.styleFrom(
       padding: const EdgeInsets.symmetric(vertical: 16),
      ),
     ),
    ],
   ),
  );
 }
}