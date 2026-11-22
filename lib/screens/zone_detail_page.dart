import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/interventions_provider.dart';
import 'package:agrismart/services/scan_service.dart';
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

 void _afficherQr(BuildContext context) {
  final traduction = context.read<TraductionProvider>();
  showDialog<void>(
   context: context,
   builder: (ctx) => AlertDialog(
    title: Text('${traduction.tr('qrDeLaZone')} : ${zone.nom}'),
    content: Column(
     mainAxisSize: MainAxisSize.min,
     children: [
      // Fond blanc obligatoire, même en thème sombre, pour que le QR soit lisible.
      QrImageView(
       data: CodeZone.encoder(zone.nom),
       size: 220,
       backgroundColor: Colors.white,
       padding: const EdgeInsets.all(8),
      ),
      const SizedBox(height: 12),
      Text(traduction.tr('qrAide'), textAlign: TextAlign.center),
     ],
    ),
    actions: [
     TextButton(onPressed: () => Navigator.pop(ctx), child: Text(traduction.tr('fermer'))),
    ],
   ),
  );
 }

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
  final suivi = context.watch<InterventionsProvider>();
  final interventions = suivi.deZone(zone.nom);
  final restriction = suivi.recolteAutoriseeLe(zone.nom);

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
     const SizedBox(height: 16),

     if (restriction != null)
      Card(
       color: AppTheme.echec.withValues(alpha: 0.12),
       child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: AppTheme.echec),
        title: Text(
         '${traduction.tr('recolteDeconseilleeJusquau')} ${formaterDate(restriction)}',
         style: const TextStyle(color: AppTheme.echec, fontWeight: FontWeight.w600),
        ),
       ),
      ),

     Text(traduction.tr('journalInterventions'), style: texte.titleMedium),
     const SizedBox(height: 8),
     if (interventions.isEmpty)
      Text(traduction.tr('aucuneIntervention'))
     else
      Card(
       child: Column(
        children: [
         for (final i in interventions)
          ListTile(
           leading: Icon(
            i.culturePrevue ? Icons.science_outlined : Icons.warning_amber_rounded,
            color: i.culturePrevue ? null : AppTheme.echec,
           ),
           title: Text(i.intrant.nom),
           subtitle: Text(
            '${formaterDate(i.date)} · ${traduction.tr('delaiAvantRecolte')} : '
                '${i.intrant.delaiAvantRecolteJours} ${traduction.tr('jours')}',
           ),
          ),
        ],
       ),
      ),
     const SizedBox(height: 24),

     OutlinedButton.icon(
      onPressed: () => _afficherQr(context),
      icon: const Icon(Icons.qr_code_2),
      label: Text(traduction.tr('qrDeLaZone')),
      style: OutlinedButton.styleFrom(
       padding: const EdgeInsets.symmetric(vertical: 16),
      ),
     ),
     const SizedBox(height: 12),

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