import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/traduction_provider.dart';

class ZoneCard extends StatelessWidget {
  final Zone zone;
  final VoidCallback onAugmenter;
  final VoidCallback onDiminuer;
  final VoidCallback? onToggleVanne;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ZoneCard({
    super.key,
    required this.zone,
    required this.onAugmenter,
    required this.onDiminuer,
    this.onToggleVanne,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();
    final couleur = zone.besoinIrrigation ? Colors.red : Colors.green;

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
                        if (onToggleVanne != null)
                          InkWell(
                            onTap: onToggleVanne,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: zone.vanneOuverte
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: zone.vanneOuverte ? Colors.blue : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    zone.vanneOuverte ? Icons.water_drop : Icons.water_drop_outlined,
                                    size: 14,
                                    color: zone.vanneOuverte ? Colors.blue : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    zone.vanneOuverte
                                        ? traduction.tr('ouverte')
                                        : traduction.tr('fermee'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: zone.vanneOuverte ? Colors.blue : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
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
                children: [
                  Text('${zone.humidite.toStringAsFixed(0)} %'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onDiminuer,
                        icon: const Icon(Icons.remove),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: onAugmenter,
                        icon: const Icon(Icons.add),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
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
