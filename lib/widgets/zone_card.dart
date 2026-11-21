import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/traduction_provider.dart';

class ZoneCard extends StatelessWidget {
  final Zone zone;
  final VoidCallback onAugmenter;
  final VoidCallback onDiminuer;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ZoneCard({
    super.key,
    required this.zone,
    required this.onAugmenter,
    required this.onDiminuer,
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
                    Text(zone.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      zone.besoinIrrigation
                          ? traduction.tr('besoinIrrigation')
                          : traduction.tr('solCorrect'),
                      style: TextStyle(color: couleur, fontSize: 12),
                    ),
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
                      IconButton(onPressed: onDiminuer, icon: const Icon(Icons.remove)),
                      IconButton(onPressed: onAugmenter, icon: const Icon(Icons.add)),
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