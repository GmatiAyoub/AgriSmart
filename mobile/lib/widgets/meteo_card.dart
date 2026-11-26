import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/meteo.dart';
import 'package:agrismart/providers/meteo_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';

class MeteoCard extends StatelessWidget {
  const MeteoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeteoProvider>();
    final traduction = context.watch<TraductionProvider>();
    final Widget contenu;

    switch (provider.etat) {
      case EtatMeteo.chargement:
        contenu = Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(traduction.tr('chargementMeteo')),
              ],
            ),
          ),
        );

      case EtatMeteo.erreur:
        contenu = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 40, color: Colors.orange),
              const SizedBox(height: 8),
              Text(provider.erreur),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => context.read<MeteoProvider>().charger(),
                child: Text(traduction.tr('reessayer')),
              ),
            ],
          ),
        );

      case EtatMeteo.succes:
        contenu = _Contenu(
          meteo: provider.meteo!,
          horsLigne: provider.horsLigne,
          miseAJour: provider.miseAJour,
        );
    }

    return Card(
      elevation: 2,
      child: contenu,
    );
  }
}

class _Contenu extends StatelessWidget {
  final Meteo meteo;
  final bool horsLigne;
  final DateTime? miseAJour;

  const _Contenu({
    required this.meteo,
    required this.horsLigne,
    required this.miseAJour,
  });

  static String _deux(int n) => n.toString().padLeft(2, '0');

  String _libelleMiseAJour(TraductionProvider traduction) {
    final d = miseAJour;

    if (d == null) {
      return horsLigne ? traduction.tr('donneesHorsLigne') : '';
    }

    final quand =
        '${_deux(d.day)}/${_deux(d.month)} ${traduction.tr('a')} ${_deux(d.hour)}:${_deux(d.minute)}';

    return horsLigne
        ? '${traduction.tr('horsLigneDu')} $quand'
        : '${traduction.tr('miseAJourLe')} $quand';
  }

  static const _joursFr = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _joursAr = ['إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();
    final theme = Theme.of(context);
    final pluie = meteo.pluieTotale;

    final String conseil;
    if (traduction.estArabe) {
      conseil = pluie >= 5
          ? 'أمطار متوقعة (${pluie.toStringAsFixed(1)} مم) : تأجيل الري'
          : 'لا توجد أمطار هامة متوقعة';
    } else {
      conseil = pluie >= 5
          ? 'Pluie prévue (${pluie.toStringAsFixed(1)} mm) : repoussez l\'irrigation'
          : 'Pas de pluie significative prévue';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 8),
              Text(
                traduction.tr('meteoKebili'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                '${meteo.temperature.toStringAsFixed(0)} °C',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(
                        "${traduction.tr('humiditeAir')} : ${meteo.humiditeAir} %",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.air_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${traduction.tr('vent')} : ${meteo.vent.toStringAsFixed(0)} km/h",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 24),

          for (final p in meteo.previsions)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 95,
                    child: Text(
                      () {
                        final maintenant = DateTime.now();
                        final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
                        final datePrevision = DateTime(p.date.year, p.date.month, p.date.day);
                        final difference = datePrevision.difference(aujourdhui).inDays;

                        if (difference == 0) return traduction.tr('aujourdhui');
                        if (difference == 1) return traduction.tr('demain');
                        if (difference == 2) return traduction.tr('apresDemain');

                        final index = p.date.weekday - 1;
                        return traduction.estArabe ? _joursAr[index] : _joursFr[index];
                      }(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      '${p.tMin.toStringAsFixed(0)}° / ${p.tMax.toStringAsFixed(0)}°',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),

                  const Icon(Icons.water_drop_outlined, size: 15, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  Text(
                    '${p.pluie.toStringAsFixed(1)} mm',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: pluie >= 5
                  ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                  : const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: pluie >= 5
                    ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                    : const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  pluie >= 5 ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: pluie >= 5 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conseil,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: pluie >= 5 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_libelleMiseAJour(traduction).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _libelleMiseAJour(traduction),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey),
            ),
          ],

          if (horsLigne)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                onPressed: () => context.read<MeteoProvider>().charger(),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(traduction.tr('reessayer')),
              ),
            ),
        ],
      ),
    );
  }
}
