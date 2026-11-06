import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/screens/zone_detail_page.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/widgets/fiche_exploitation.dart';
import 'package:agrismart/widgets/resume_exploitation.dart';
import 'package:agrismart/widgets/zone_card.dart';

class ZonesPage extends StatelessWidget {
  const ZonesPage({super.key});

  void _message(BuildContext context, String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _ajouter(BuildContext context) async {
    final noms = context.read<ZonesProvider>().noms();
    final nouvelle = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(builder: (_) => ZoneFormPage(nomsExistants: noms)),
    );
    if (nouvelle == null || !context.mounted) return;
    context.read<ZonesProvider>().ajouter(nouvelle);
    _message(context, 'Zone ajoutée');
  }

  Future<void> _ouvrirDetail(BuildContext context, Zone zone) async {
    final noms = context.read<ZonesProvider>().noms(sauf: zone);
    final modifiee = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneDetailPage(zone: zone, nomsAutres: noms),
      ),
    );
    if (modifiee == null || !context.mounted) return;
    context.read<ZonesProvider>().remplacer(zone, modifiee);
    _message(context, 'Zone modifiée');
  }

  Future<void> _confirmerSuppression(BuildContext context, Zone zone) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la zone ?'),
        content: Text('La zone ${zone.nom} sera supprimée définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;
    context.read<ZonesProvider>().supprimer(zone);
    _message(context, 'Zone supprimée');
  }

  Widget _carte(BuildContext context, Zone zone) {
    final provider = context.read<ZonesProvider>();
    return ZoneCard(
      zone: zone,
      onAugmenter: () => provider.modifierHumidite(zone, 5),
      onDiminuer: () => provider.modifierHumidite(zone, -5),
      onTap: () => _ouvrirDetail(context, zone),
      onLongPress: () => _confirmerSuppression(context, zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonesAffichees = context.watch<ZonesProvider>().zonesAffichees;
    final toutesLesZones = context.watch<ZonesProvider>().zones;
    final filtreActif = context.watch<ZonesProvider>().seulementAIrriguer; // 🆕

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('AgriSmart'),
        actions: [
          // 🆕 Exercice 1 : Le bouton de filtre
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
          // La fiche utilise TOUTES les zones pour la moyenne
          FicheExploitation(humiditeMoyenne: humiditeMoyenne(toutesLesZones)),
          ResumeExploitation(zones: toutesLesZones),
          Expanded(
            child: zonesAffichees.isEmpty
                ? const Center(child: Text('Aucune zone pour le moment'))
                : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 600) {
                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.8,
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