import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/screens/a_propos_page.dart';
import 'package:agrismart/providers/auth_provider.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;

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
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // Avatar
          const Center(
            child: CircleAvatar(
              radius: 40,
              child: Icon(Icons.agriculture, size: 40),
            ),
          ),

          const SizedBox(height: 12),

          // Nom de l'utilisateur connecté
          Center(
            child: Text(
              nom,
              style: texte.titleLarge,
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Center(
            child: Text(email),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // TP5 : Nombre de zones
          ListTile(
            leading: const Icon(Icons.grass),
            title: const Text('Zones suivies'),
            trailing: Text('$nombreZones'),
          ),

          // Exercice 2 : Zones à irriguer
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text('Zones à irriguer'),
            trailing: Text(
              '$aIrriguer',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),

          // Humidité moyenne
          ListTile(
            leading: const Icon(Icons.water),
            title: const Text('Humidité moyenne'),
            trailing: Text('${moyenne.toStringAsFixed(1)} %'),
          ),

          const Divider(),

          // TP4 : À propos
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
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

          // TP6 : Déconnexion
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Se déconnecter'),
            onTap: () => _confirmerDeconnexion(context),
          ),
        ],
      ),
    );
  }

  // TP6 : Confirmation avant déconnexion
  Future<void> _confirmerDeconnexion(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;

    // AuthGate revient automatiquement à l'écran de connexion
    await context.read<AuthProvider>().deconnexion();
  }
}