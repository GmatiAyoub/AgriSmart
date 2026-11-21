import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/screens/a_propos_page.dart';
import 'package:agrismart/providers/auth_provider.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final traduction = context.watch<TraductionProvider>();

    final nombreZones = context.select<ZonesProvider, int>(
          (p) => p.nombre,
    );

    final aIrriguer = context.select<ZonesProvider, int>(
          (p) => p.nombreAIrriguer,
    );

    final moyenne = context.select<ZonesProvider, double>(
          (p) => humiditeMoyenne(p.zones),
    );

    final nom = context.select<AuthProvider, String>(
          (a) => a.utilisateur?.nom ?? '',
    );

    final email = context.select<AuthProvider, String>(
          (a) => a.utilisateur?.email ?? '',
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(traduction.tr('profil')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          const Center(
            child: CircleAvatar(
              radius: 40,
              child: Icon(Icons.agriculture, size: 40),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              nom,
              style: texte.titleLarge,
            ),
          ),

          const SizedBox(height: 4),

          Center(
            child: Text(email),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Sélecteur de langue
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue / اللغة'),
            subtitle: Text(traduction.estArabe ? 'العربية' : 'Français'),
            trailing: SegmentedButton<LangueApp>(
              segments: const [
                ButtonSegment(value: LangueApp.fr, label: Text('FR')),
                ButtonSegment(value: LangueApp.ar, label: Text('عربي')),
              ],
              selected: {traduction.langueActuelle},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  context.read<TraductionProvider>().fixerLangue(set.first);
                }
              },
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.grass),
            title: Text(traduction.tr('zonesSuivies')),
            trailing: Text('$nombreZones'),
          ),

          ListTile(
            leading: const Icon(Icons.water_drop),
            title: Text(traduction.tr('zonesAIrriguer')),
            trailing: Text(
              '$aIrriguer',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.water),
            title: Text(traduction.tr('humiditeMoyenne')),
            trailing: Text('${moyenne.toStringAsFixed(1)} %'),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(traduction.tr('aPropos')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AProposPage(),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(traduction.tr('seDeconnecter')),
            onTap: () => _confirmerDeconnexion(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerDeconnexion(BuildContext context) async {
    final traduction = context.read<TraductionProvider>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(traduction.tr('confirmerDeconnexion')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(traduction.tr('annuler')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(traduction.tr('seDeconnecter')),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;

    await context.read<AuthProvider>().deconnexion();
  }
}