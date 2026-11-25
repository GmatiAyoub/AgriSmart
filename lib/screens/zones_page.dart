import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/screens/diagnostic_page.dart';
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
    final modifiee = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneDetailPage(zone: zone, nomsAutres: noms),
      ),
    );
    if (modifiee == null || !context.mounted) return;
    context.read<ZonesProvider>().remplacer(zone, modifiee);
    _message(context, traduction.tr('zoneModifiee'));
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
    final provider = context.read<ZonesProvider>();
    final traduction = context.read<TraductionProvider>();

    return ZoneCard(
      zone: zone,
      onIrriguer: () async {
        await provider.irriguerParcelle(zone);
        if (context.mounted) {
          final statut = zone.auMoinsUneVanneOuverte
              ? traduction.tr('irriguer')
              : traduction.tr('arreterIrrigation');
          _message(context, '${zone.nom} : $statut');
        }
      },
      onTap: () => _ouvrirDetail(context, zone),
      onLongPress: () => _confirmerSuppression(context, zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zonesProvider = context.watch<ZonesProvider>();
    final zonesAffichees = zonesProvider.zonesAffichees;
    final toutesLesZones = zonesProvider.zones;
    final filtreActif = zonesProvider.seulementAIrriguer;
    final estEnLigne = zonesProvider.estEnLigneRest;
    final traduction = context.watch<TraductionProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(traduction.tr('appTitle')),
        actions: [
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
      body: RefreshIndicator(
        onRefresh: () => context.read<ZonesProvider>().chargerDepuisApi(),
        child: Column(
          children: [
            // Bandeau d'état REST API (Connecté / Local)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: estEnLigne ? Colors.green.shade50 : Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(
                    estEnLigne ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: estEnLigne ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      estEnLigne
                          ? traduction.tr('serveurConnecte')
                          : traduction.tr('serveurDeconnecte'),
                      style: TextStyle(
                        fontSize: 12,
                        color: estEnLigne ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    tooltip: traduction.tr('synchroApi'),
                    onPressed: () => context.read<ZonesProvider>().chargerDepuisApi(),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}
