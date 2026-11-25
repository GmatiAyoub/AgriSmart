import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/parcelle_api.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/traduction_provider.dart';

class ZoneCard extends StatefulWidget {
  final Zone zone;
  final ParcelleApi? parcelle; // parcelle du serveur (null = pas encore creee)
  final Future<void> Function()? onIrriguer; // ouvre / ferme ses vannes
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ZoneCard({
    super.key,
    required this.zone,
    this.parcelle,
    this.onIrriguer,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<ZoneCard> createState() => _ZoneCardState();
}

class _ZoneCardState extends State<ZoneCard> {
  bool _enCours = false;

  Future<void> _irriguer() async {
    setState(() => _enCours = true);
    try {
      await widget.onIrriguer?.call();
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  int get _nbVannes => widget.parcelle?.nombreVannes ?? 0;
  bool get _enIrrigation => widget.parcelle?.irrigationActive ?? false;

  Widget _boutonIrrigation() {
    if (_nbVannes == 0) {
      return const SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: null,
          child: Text('Pas de vanne'),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: _enIrrigation ? Colors.red.shade400 : Colors.blue,
        ),
        onPressed: _enCours ? null : _irriguer,
        icon: _enCours
            ? const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Icon(_enIrrigation ? Icons.stop_circle_outlined : Icons.water_drop,
            size: 16),
        label: Text(_enIrrigation ? 'Arrêter' : 'Irriguer'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final traduction = context.watch<TraductionProvider>();
    final couleur = zone.besoinIrrigation ? Colors.red : Colors.green;
    final nb = _nbVannes;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
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
                    Text(zone.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      zone.besoinIrrigation
                          ? traduction.tr('besoinIrrigation')
                          : traduction.tr('solCorrect'),
                      style: TextStyle(color: couleur, fontSize: 12),
                    ),
                    Text(
                      _enIrrigation
                          ? 'Irrigation en cours…'
                          : (nb == 0
                          ? 'Aucune vanne'
                          : '$nb vanne${nb > 1 ? 's' : ''}'),
                      style: TextStyle(
                        color: _enIrrigation ? Colors.blue : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                  const SizedBox(height: 8),
                  _boutonIrrigation(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
