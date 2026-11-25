import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/parcelle_api.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/screens/diagnostic_page.dart';
import 'package:agrismart/screens/zone_detail_page.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/widgets/fiche_exploitation.dart';
import 'package:agrismart/widgets/resume_exploitation.dart';
import 'package:agrismart/widgets/zone_card.dart';
import 'package:agrismart/services/api_client.dart';
import 'package:agrismart/services/parcelle_service.dart';

// Humidite gagnee par une parcelle apres une irrigation (en %)
const double _pasIrrigation = 15;

class ZonesPage extends StatefulWidget {
  const ZonesPage({super.key});

  @override
  State<ZonesPage> createState() => _ZonesPageState();
}

class _ZonesPageState extends State<ZonesPage> {
  final _parcelleService = ParcelleService();
  Map<String, ParcelleApi> _parcelles = {}; // nom (normalise) -> parcelle du serveur

  @override
  void initState() {
    super.initState();
    _chargerParcelles();
  }

  ParcelleApi? _parcelle(Zone zone) => _parcelles[ParcelleApi.cle(zone.nom)];

  Future<void> _chargerParcelles() async {
    try {
      final liste = await _parcelleService.lister();
      if (!mounted) return;
      setState(() {
        _parcelles = {for (final p in liste) ParcelleApi.cle(p.nom): p};
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _message(context, e.message);
    }
  }

  // Bouton Irriguer : ouvre toutes les vannes de la parcelle (ou les ferme)
  Future<void> _irriguer(Zone zone) async {
    final parcelle = _parcelle(zone);
    if (parcelle == null || parcelle.nombreVannes == 0) return;
    final ouvrir = !parcelle.irrigationActive;

    try {
      await _parcelleService.irrigation(parcelle.id, ouvrir: ouvrir);
      await _chargerParcelles();
      if (!mounted) return;
      // L'irrigation fait monter l'humidite : l'etat de la parcelle change
      if (ouvrir) {
        context.read<ZonesProvider>().modifierHumidite(zone, _pasIrrigation);
      }
      _message(
        context,
        ouvrir
            ? 'Irrigation lancée : ${zone.nom}'
            : 'Irrigation arrêtée : ${zone.nom}',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _message(context, e.message);
    }
  }

  void _message(BuildContext context, String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _ajouter(BuildContext context) async {
    final traduction = context.read<TraductionProvider>();
    final noms = context.read<ZonesProvider>().noms();
    final nouvelle = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(builder: (_) => ZoneFormPage(nomsExistants: noms)),
    );
    if (nouvelle == null || !context.mounted) return;
    context.read<ZonesProvider>().ajouter(nouvelle);
    _message(context, traduction.tr('zoneAjoutee'));
  }

  Future<void> _ouvrirDetail(BuildContext context, Zone zone) async {
    final traduction = context.read<TraductionProvider>();
    final noms = context.read<ZonesProvider>().noms(sauf: zone);
    final parcelle = _parcelle(zone);
    final modifiee = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneDetailPage(
          zone: zone,
          nomsAutres: noms,
          parcelle: parcelle,
        ),
      ),
    );
    if (!context.mounted) return;

    if (modifiee != null) {
      // garde le lien avec la parcelle du serveur si le nom change
      if (parcelle != null && modifiee.nom != zone.nom) {
        try {
          await _parcelleService.renommer(parcelle.id, modifiee.nom);
        } on ApiException catch (e) {
          if (context.mounted) _message(context, e.message);
        }
      }
      if (!context.mounted) return;
      context.read<ZonesProvider>().remplacer(zone, modifiee);
      _message(context, traduction.tr('zoneModifiee'));
    }
    _chargerParcelles(); // les vannes ont pu changer dans le detail
  }

  Future<void> _confirmerSuppression(BuildContext context, Zone zone) async {
    final traduction = context.read<TraductionProvider>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(traduction.tr('supprimerZone')),
        content: Text(zone.nom),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(traduction.tr('annuler'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(traduction.tr('supprimer'))),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;
    context.read<ZonesProvider>().supprimer(zone);
    _message(context, traduction.tr('zoneSupprimee'));
  }

  Widget _carte(BuildContext context, Zone zone) {
    return ZoneCard(
      zone: zone,
      parcelle: _parcelle(zone),
      onIrriguer: () => _irriguer(zone),
      onTap: () => _ouvrirDetail(context, zone),
      onLongPress: () => _confirmerSuppression(context, zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonesAffichees = context.watch<ZonesProvider>().zonesAffichees;
    final toutesLesZones = context.watch<ZonesProvider>().zones;
    final filtreActif = context.watch<ZonesProvider>().seulementAIrriguer;
    final traduction = context.watch<TraductionProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(traduction.tr('appTitle')),
        actions: [
          // Bouton de bascule de langue (FR <-> AR)
          ActionChip(
            avatar: const Icon(Icons.language, size: 18),
            label: Text(traduction.estArabe ? 'FR' : 'عربي'),
            onPressed: () => context.read<TraductionProvider>().basculerLangue(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.eco_outlined),
            tooltip: traduction.tr('diagTitre'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiagnosticPage()),
            ),
          ),
          IconButton(
            icon: Icon(filtreActif ? Icons.filter_alt : Icons.filter_alt_off),
            onPressed: () => context.read<ZonesProvider>().basculerFiltre(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouter(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          FicheExploitation(humiditeMoyenne: humiditeMoyenne(toutesLesZones)),
          ResumeExploitation(zones: toutesLesZones),
          Expanded(
            child: zonesAffichees.isEmpty
                ? Center(child: Text(traduction.tr('aucuneZone')))
                : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 600) {
                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: zonesAffichees.length,
                    itemBuilder: (context, index) => _carte(context, zonesAffichees[index]),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: zonesAffichees.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => _carte(context, zonesAffichees[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}