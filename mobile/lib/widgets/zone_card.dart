import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/traduction_provider.dart';

class ZoneCard extends StatelessWidget {
  final Zone zone;
  final VoidCallback? onIrriguer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ZoneCard({
    super.key,
    required this.zone,
    this.onIrriguer,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();
    final couleur = zone.besoinIrrigation ? Colors.red : Colors.green;
    final irrigant = zone.auMoinsUneVanneOuverte;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: couleur.withValues(alpha: 0.2),
                child: Text(
                  zone.culture.length >= 4
                      ? zone.culture.substring(0, 4)
                      : zone.culture,
                  style: TextStyle(color: couleur, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            zone.nom,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: irrigant
                                ? Colors.blue.withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: irrigant ? Colors.blue : Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                irrigant ? Icons.water_drop : Icons.water_drop_outlined,
                                size: 14,
                                color: irrigant ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${zone.nombreVannesOuvertes}/${zone.vannes.length} ${traduction.tr("vanne")}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: irrigant ? Colors.blue : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      zone.besoinIrrigation
                          ? traduction.tr('besoinIrrigation')
                          : traduction.tr('solCorrect'),
                      style: TextStyle(color: couleur, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: zone.humidite / 100,
                      color: couleur,
                      backgroundColor: couleur.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${zone.humidite.toStringAsFixed(0)} %',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  FilledButton.icon(
                    onPressed: onIrriguer,
                    icon: Icon(
                      irrigant ? Icons.stop : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(
                      irrigant
                          ? traduction.tr('arreterIrrigation')
                          : traduction.tr('irriguer'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: irrigant ? Colors.orange.shade800 : Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
