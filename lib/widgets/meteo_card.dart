import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/meteo.dart';
import 'package:agrismart/providers/meteo_provider.dart';

class MeteoCard extends StatelessWidget {
  const MeteoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeteoProvider>();
    final Widget contenu;

    switch (provider.etat) {
      case EtatMeteo.chargement:
        contenu = const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Chargement de la météo...'),
              ],
            ),
          ),
        );

      case EtatMeteo.erreur:
        contenu = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 40),
              Text(provider.erreur),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => context.read<MeteoProvider>().charger(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        );

      case EtatMeteo.succes:
        contenu = _Contenu(meteo: provider.meteo!);
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: contenu,
    );
  }
}

class _Contenu extends StatelessWidget {
  final Meteo meteo;
  const _Contenu({required this.meteo});

  // On garde ce tableau en secours au cas où
  static const _jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final pluie = meteo.pluieTotale;
    final conseil = pluie >= 5
        ? 'Pluie prévue (${pluie.toStringAsFixed(1)} mm) : repoussez l\'irrigation'
        : 'Pas de pluie significative prévue';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Météo à Kébili', style: texte.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${meteo.temperature.toStringAsFixed(0)} °C',
                style: texte.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Humidité de l'air : ${meteo.humiditeAir} %"),
                  Text('Vent : ${meteo.vent.toStringAsFixed(0)} km/h'),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          for (final p in meteo.previsions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  // 👇 MODIFICATION ICI : L'exercice "Aller plus loin"
                  SizedBox(
                    width: 85, // Élargi pour faire rentrer "Après-demain"
                    child: Text(
                          () {
                        // On compare uniquement les dates (sans les heures)
                        final maintenant = DateTime.now();
                        final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
                        final datePrevision = DateTime(p.date.year, p.date.month, p.date.day);

                        final difference = datePrevision.difference(aujourdhui).inDays;

                        if (difference == 0) return "Aujourd'hui";
                        if (difference == 1) return 'Demain';
                        if (difference == 2) return 'Après-demain';

                        // Au cas où (ex: si l'API renvoie plus de 3 jours)
                        return _jours[p.date.weekday - 1];
                      }(),
                      style: const TextStyle(fontSize: 13), // Police un peu plus petite
                    ),
                  ),
                  // 👆 FIN DE LA MODIFICATION

                  Expanded(
                    child: Text(
                      '${p.tMin.toStringAsFixed(0)}° / ${p.tMax.toStringAsFixed(0)}°',
                    ),
                  ),
                  const Icon(Icons.water_drop_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('${p.pluie.toStringAsFixed(1)} mm'),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(conseil, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}