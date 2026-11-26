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
    final theme = Theme.of(context);
    final couleurStatus = zone.besoinIrrigation ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final irrigant = zone.auMoinsUneVanneOuverte;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Badge avatar de la culture
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: couleurStatus.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: couleurStatus.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    zone.culture.length >= 4
                        ? zone.culture.substring(0, 4)
                        : zone.culture,
                    style: TextStyle(
                      color: couleurStatus,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Informations de la parcelle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            zone.nom,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: irrigant
                                ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: irrigant ? const Color(0xFF0284C7) : Colors.grey.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                irrigant ? Icons.water_drop : Icons.water_drop_outlined,
                                size: 13,
                                color: irrigant ? const Color(0xFF0284C7) : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${zone.nombreVannesOuvertes}/${zone.vannes.length} ${traduction.tr("vanne")}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: irrigant ? const Color(0xFF0284C7) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          zone.besoinIrrigation
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 14,
                          color: couleurStatus,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          zone.besoinIrrigation
                              ? traduction.tr('besoinIrrigation')
                              : traduction.tr('solCorrect'),
                          style: TextStyle(
                            color: couleurStatus,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (zone.humidite / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        color: couleurStatus,
                        backgroundColor: couleurStatus.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Humidité % et Bouton Irriguer
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${zone.humidite.toStringAsFixed(0)} %',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: onIrriguer,
                    icon: Icon(
                      irrigant ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 16,
                    ),
                    label: Text(
                      irrigant
                          ? traduction.tr('arreterIrrigation')
                          : traduction.tr('irriguer'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: irrigant ? const Color(0xFFEA580C) : const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
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
