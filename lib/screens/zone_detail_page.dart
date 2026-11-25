import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/vanne.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
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

  Future<void> _modifier(BuildContext context, Zone zoneActuelle) async {
    final nouvelle = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneFormPage(
          zone: zoneActuelle,
          nomsExistants: nomsAutres,
        ),
      ),
    );

    if (nouvelle == null || !context.mounted) return;
    context.read<ZonesProvider>().remplacer(zoneActuelle, nouvelle);
  }

  Future<void> _dialogVanne(BuildContext context, Zone zoneActuelle, {Vanne? vanneExistante, int? index}) async {
    final traduction = context.read<TraductionProvider>();
    final ctrl = TextEditingController(text: vanneExistante?.nom ?? 'Vanne ${zoneActuelle.vannes.length + 1}');

    final resultat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(vanneExistante == null ? traduction.tr('ajouterVanne') : traduction.tr('modifierVanne')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: traduction.tr('nomVanne'),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(traduction.tr('annuler')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(traduction.tr('enregistrer')),
          ),
        ],
      ),
    );

    if (resultat == null || resultat.isEmpty || !context.mounted) return;

    final provider = context.read<ZonesProvider>();
    if (vanneExistante == null) {
      await provider.ajouterVanne(zoneActuelle, Vanne(nom: resultat));
    } else if (index != null) {
      await provider.modifierVanne(zoneActuelle, index, vanneExistante.copyWith(nom: resultat));
    }
  }

  Future<void> _supprimerVanne(BuildContext context, Zone zoneActuelle, int index, Vanne vanne) async {
    final traduction = context.read<TraductionProvider>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(traduction.tr('supprimerVanne')),
        content: Text(vanne.nom),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(traduction.tr('annuler'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(traduction.tr('supprimer'))),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;
    await context.read<ZonesProvider>().supprimerVanne(zoneActuelle, index);
  }

  @override
  Widget build(BuildContext context) {
    final zonesProvider = context.watch<ZonesProvider>();
    final traduction = context.watch<TraductionProvider>();

    // Retrouver la zone à jour dans le provider
    final zoneActuelle = zonesProvider.zones.firstWhere(
      (z) => z.id == zone.id || z.nom == zone.nom,
      orElse: () => zone,
    );

    final couleur = zoneActuelle.besoinIrrigation ? AppTheme.echec : AppTheme.succes;
    final longueur = zoneActuelle.culture.length < 4 ? zoneActuelle.culture.length : 4;
    final texte = Theme.of(context).textTheme;
    final irrigant = zoneActuelle.auMoinsUneVanneOuverte;

    return Scaffold(
      appBar: AppBar(
        title: Text(zoneActuelle.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: traduction.tr('modifierZone'),
            onPressed: () => _modifier(context, zoneActuelle),
          ),
        ],
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
                  zoneActuelle.culture.substring(0, longueur),
                  style: TextStyle(color: couleur, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zoneActuelle.nom, style: texte.headlineSmall),
                    Text(zoneActuelle.culture, style: texte.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              '${zoneActuelle.humidite.toStringAsFixed(0)} %',
              style: texte.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: zoneActuelle.humidite / 100,
            color: couleur,
            backgroundColor: couleur.withValues(alpha: 0.2),
            minHeight: 10,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              zoneActuelle.besoinIrrigation ? traduction.tr('besoinIrrigation') : traduction.tr('solCorrect'),
              style: TextStyle(
                color: couleur,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bouton d'Irrigation globale de la parcelle
          FilledButton.icon(
            onPressed: () => context.read<ZonesProvider>().irriguerParcelle(zoneActuelle),
            icon: Icon(irrigant ? Icons.stop : Icons.play_arrow),
            label: Text(
              irrigant
                  ? '${traduction.tr("arreterIrrigation")} (${zoneActuelle.nombreVannesOuvertes}/${zoneActuelle.vannes.length})'
                  : '${traduction.tr("irriguer")} (${zoneActuelle.vannes.length} ${traduction.tr("vannes")})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: irrigant ? Colors.orange.shade800 : Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 24),

          // Section Gestion des Vannes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${traduction.tr("vannes")} (${zoneActuelle.vannes.length})',
                style: texte.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              OutlinedButton.icon(
                onPressed: () => _dialogVanne(context, zoneActuelle),
                icon: const Icon(Icons.add, size: 18),
                label: Text(traduction.tr('ajouterVanne')),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (zoneActuelle.vannes.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(traduction.tr('aucuneVanne')),
                ),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: zoneActuelle.vannes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final v = zoneActuelle.vannes[i];
                  return ListTile(
                    leading: Icon(
                      v.estOuverte ? Icons.water_drop : Icons.water_drop_outlined,
                      color: v.estOuverte ? Colors.blue : Colors.grey,
                    ),
                    title: Text(v.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      v.estOuverte ? traduction.tr('ouverte') : traduction.tr('fermee'),
                      style: TextStyle(
                        color: v.estOuverte ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: v.estOuverte,
                          onChanged: (_) => context.read<ZonesProvider>().basculerVanne(zoneActuelle, i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: traduction.tr('modifierVanne'),
                          onPressed: () => _dialogVanne(context, zoneActuelle, vanneExistante: v, index: i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          tooltip: traduction.tr('supprimerVanne'),
                          onPressed: () => _supprimerVanne(context, zoneActuelle, i, v),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
