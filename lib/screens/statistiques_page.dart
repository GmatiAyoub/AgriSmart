import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/theme/app_theme.dart';
import 'package:agrismart/widgets/resume_exploitation.dart';
import 'package:agrismart/widgets/meteo_card.dart';

class StatistiquesPage extends StatelessWidget {
  const StatistiquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final zones = context.watch<ZonesProvider>().zones;
    final traduction = context.watch<TraductionProvider>();

    final tri = [...zones]..sort((a, b) => a.humidite.compareTo(b.humidite));
    final aIrriguer = zones.where((z) => z.besoinIrrigation).length;
    final pourcentage = zones.isEmpty ? 0 : (aIrriguer * 100 / zones.length).round();

    final sentence = traduction.estArabe
        ? '$aIrriguer ${traduction.tr('statSentence')} ${zones.length} ${traduction.tr('statSentenceEnd')} ($pourcentage %)'
        : '$aIrriguer ${traduction.tr('statSentence')} ${zones.length} ${traduction.tr('statSentenceEnd')} ($pourcentage %)';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(traduction.tr('statistiques')),
      ),
      body: ListView(
        children: [
          const MeteoCard(),

          if (zones.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(traduction.tr('aucuneDonnee'))),
            )
          else ...[
            ResumeExploitation(zones: zones),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sentence,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(traduction.tr('humiditeParZone'), style: Theme.of(context).textTheme.titleMedium),
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