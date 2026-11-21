import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/theme/app_theme.dart';
import 'package:agrismart/widgets/resume_exploitation.dart';
import 'package:agrismart/widgets/meteo_card.dart'; // L'import est déjà là, c'est parfait

class StatistiquesPage extends StatelessWidget {
  const StatistiquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // watch : la page est reconstruite à chaque changement
    final zones = context.watch<ZonesProvider>().zones;

    final tri = [...zones]..sort((a, b) => a.humidite.compareTo(b.humidite));
    final aIrriguer = zones.where((z) => z.besoinIrrigation).length;
    final pourcentage = zones.isEmpty ? 0 : (aIrriguer * 100 / zones.length).round();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Statistiques'),
      ),
      // 👇 MODIFICATION ICI : On utilise toujours un ListView
      body: ListView(
        children: [
          // 1. La carte météo est TOUJOURS affichée en premier
          const MeteoCard(),

          // 2. Si la liste des zones est vide
          if (zones.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Aucune donnée à afficher')),
            )
          // 3. Sinon, on affiche le reste de votre contenu d'origine
          else ...[
            ResumeExploitation(zones: zones),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$aIrriguer zone(s) sur ${zones.length} à irriguer ($pourcentage %)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Humidité par zone', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final z in tri)
                    ListTile(
                      title: Text(z.nom),
                      subtitle: LinearProgressIndicator(
                        value: z.humidite / 100,
                        color: z.besoinIrrigation ? AppTheme.echec : AppTheme.succes,
                      ),
                      trailing: Text('${z.humidite.toStringAsFixed(0)} %'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}