import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/screens/a_propos_page.dart'; // 👈 Le bouton du TP4

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;

    // 🆕 Exercice 2 : Les 3 Select
    final nombreZones = context.select<ZonesProvider, int>((p) => p.nombre);
    final aIrriguer = context.select<ZonesProvider, int>((p) => p.nombreAIrriguer);
    final moyenne = context.select<ZonesProvider, double>((p) => humiditeMoyenne(p.zones));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Profil'),
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
          Center(child: Text('Exploitation AgriSmart', style: texte.titleLarge)),
          const Center(child: Text('Kébili, Tunisie')),
          const SizedBox(height: 16),
          const Divider(),

          // TP5 : Nombre de zones
          ListTile(
            leading: const Icon(Icons.grass),
            title: const Text('Zones suivies'),
            trailing: Text('$nombreZones'),
          ),

          // 🆕 Exercice 2 : Les deux nouvelles lignes
          ListTile(
            leading: const Icon(Icons.water_drop),
            title: const Text('Zones à irriguer'),
            trailing: Text('$aIrriguer', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          ListTile(
            leading: const Icon(Icons.water),
            title: const Text('Humidité moyenne'),
            trailing: Text('${moyenne.toStringAsFixed(1)} %'),
          ),

          const Divider(),

          // TP4 Oublié : Le bouton À propos
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AProposPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}