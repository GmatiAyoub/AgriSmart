import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/parcelle_api.dart';
import 'package:agrismart/models/vanne.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/services/api_client.dart';
import 'package:agrismart/services/parcelle_service.dart';
import 'package:agrismart/services/vanne_service.dart';
import 'package:agrismart/theme/app_theme.dart';

class ZoneDetailPage extends StatefulWidget {
 final Zone zone;
 final List<String> nomsAutres;
 final ParcelleApi? parcelle; // parcelle du serveur (null = pas encore creee)

 const ZoneDetailPage({
  super.key,
  required this.zone,
  this.nomsAutres = const [],
  this.parcelle,
 });

 @override
 State<ZoneDetailPage> createState() => _ZoneDetailPageState();
}

class _ZoneDetailPageState extends State<ZoneDetailPage> {
 final _parcelleService = ParcelleService();
 final _vanneService = VanneService();

 ParcelleApi? _parcelle;
 List<Vanne> _vannes = [];
 bool _chargement = false;
 String? _erreur;

 @override
 void initState() {
  super.initState();
  _parcelle = widget.parcelle;
  if (_parcelle != null) {
   _chargement = true;
   _charger();
  }
 }

 // ---------- Vannes (API) ----------

 Future<void> _charger() async {
  final parcelle = _parcelle;
  if (parcelle == null) return;
  try {
   final liste = await _vanneService.lister(parcelleId: parcelle.id);
   if (!mounted) return;
   setState(() {
    _vannes = liste;
    _chargement = false;
    _erreur = null;
   });
  } on ApiException catch (e) {
   if (!mounted) return;
   setState(() {
    _chargement = false;
    _erreur = e.message;
   });
  }
 }

 void _message(String texte) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
 }

 Future<String?> _demanderNom({required String titre, String initial = ''}) async {
  final controleur = TextEditingController(text: initial);
  final nom = await showDialog<String>(
   context: context,
   builder: (ctx) => AlertDialog(
    title: Text(titre),
    content: TextField(
     controller: controleur,
     autofocus: true,
     decoration: const InputDecoration(labelText: 'Nom de la vanne'),
    ),
    actions: [
     TextButton(
      onPressed: () => Navigator.pop(ctx),
      child: const Text('Annuler'),
     ),
     FilledButton(
      onPressed: () => Navigator.pop(ctx, controleur.text.trim()),
      child: const Text('Enregistrer'),
     ),
    ],
   ),
  );
  return (nom == null || nom.isEmpty) ? null : nom;
 }

 Future<void> _ajouter() async {
  final nom = await _demanderNom(titre: 'Ajouter une vanne');
  if (nom == null) return;
  try {
   // cree la parcelle sur le serveur si elle n'existe pas encore
   final parcelle =
       _parcelle ?? await _parcelleService.assurer(widget.zone.nom);
   _parcelle = parcelle;
   await _vanneService.creer(nom, parcelle.id);
   if (!mounted) return;
   _message('Vanne ajoutée');
   await _charger();
  } on ApiException catch (e) {
   if (!mounted) return;
   _message(e.message);
  }
 }

 Future<void> _modifierVanne(Vanne vanne) async {
  final nom = await _demanderNom(titre: 'Modifier la vanne', initial: vanne.nom);
  if (nom == null) return;
  try {
   await _vanneService.renommer(vanne.id, nom);
   if (!mounted) return;
   _message('Vanne modifiée');
   await _charger();
  } on ApiException catch (e) {
   if (!mounted) return;
   _message(e.message);
  }
 }

 Future<void> _supprimerVanne(Vanne vanne) async {
  final confirme = await showDialog<bool>(
   context: context,
   builder: (ctx) => AlertDialog(
    title: const Text('Supprimer la vanne ?'),
    content: Text(vanne.nom),
    actions: [
     TextButton(
      onPressed: () => Navigator.pop(ctx, false),
      child: const Text('Annuler'),
     ),
     FilledButton(
      onPressed: () => Navigator.pop(ctx, true),
      child: const Text('Supprimer'),
     ),
    ],
   ),
  );
  if (confirme != true) return;
  try {
   await _vanneService.supprimer(vanne.id);
   if (!mounted) return;
   _message('Vanne supprimée');
   await _charger();
  } on ApiException catch (e) {
   if (!mounted) return;
   _message(e.message);
  }
 }

 Future<void> _basculer(Vanne vanne, bool ouvrir) async {
  try {
   await _vanneService.commander(vanne.id, ouvrir: ouvrir);
   if (!mounted) return;
   _message(ouvrir ? 'Vanne ouverte' : 'Vanne fermée');
  } on ApiException catch (e) {
   if (!mounted) return;
   _message(e.message);
  }
  await _charger();
 }

 // ---------- Zone ----------

 Future<void> _modifierZone() async {
  final nouvelle = await Navigator.push<Zone>(
   context,
   MaterialPageRoute(
    builder: (_) => ZoneFormPage(
     zone: widget.zone,
     nomsExistants: widget.nomsAutres,
    ),
   ),
  );

  if (nouvelle == null || !mounted) return;
  Navigator.pop(context, nouvelle);
 }

 // ---------- UI ----------

 Widget _sectionVannes() {
  final Widget contenu;
  if (_chargement) {
   contenu = const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator()),
   );
  } else if (_erreur != null) {
   contenu = Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
     children: [
      Text(_erreur!),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: _charger, child: const Text('Réessayer')),
     ],
    ),
   );
  } else if (_vannes.isEmpty) {
   contenu = const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Aucune vanne pour cette parcelle'),
   );
  } else {
   contenu = Column(
    children: [
     for (final v in _vannes)
      ListTile(
       leading: Icon(
        Icons.water_drop,
        color: v.ouverte ? Colors.blue : Colors.grey,
       ),
       title: Text(v.nom),
       subtitle: Text(v.ouverte ? 'Ouverte' : 'Fermée'),
       trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
         Switch(
          value: v.ouverte,
          onChanged: (valeur) => _basculer(v, valeur),
         ),
         PopupMenuButton<String>(
          onSelected: (choix) {
           if (choix == 'modifier') _modifierVanne(v);
           if (choix == 'supprimer') _supprimerVanne(v);
          },
          itemBuilder: (_) => const [
           PopupMenuItem(value: 'modifier', child: Text('Modifier')),
           PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
          ],
         ),
        ],
       ),
      ),
    ],
   );
  }

  return Card(
   elevation: 2,
   child: Column(
    children: [
     ListTile(
      title: Text(
       'Vannes (${_vannes.length})',
       style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: IconButton(
       icon: const Icon(Icons.add_circle_outline),
       tooltip: 'Ajouter une vanne',
       onPressed: _ajouter,
      ),
     ),
     const Divider(height: 1),
     contenu,
    ],
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  final zone = widget.zone;
  final traduction = context.watch<TraductionProvider>();
  final couleur = zone.besoinIrrigation ? AppTheme.echec : AppTheme.succes;
  final longueur = zone.culture.length < 4 ? zone.culture.length : 4;
  final texte = Theme.of(context).textTheme;

  return Scaffold(
   appBar: AppBar(title: Text(zone.nom)),
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
         style: TextStyle(
             color: couleur, fontSize: 18, fontWeight: FontWeight.bold),
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
       zone.besoinIrrigation
           ? traduction.tr('besoinIrrigation')
           : traduction.tr('solCorrect'),
       style: TextStyle(
           color: couleur, fontSize: 18, fontWeight: FontWeight.w600),
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
       ],
      ),
     ),
     const SizedBox(height: 16),
     _sectionVannes(),
     const SizedBox(height: 24),
     FilledButton.icon(
      onPressed: _modifierZone,
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
