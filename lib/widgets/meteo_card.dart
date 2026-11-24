
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
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
              const Icon(Icons.cloud_off, size: 40),
              Text(provider.erreur),
              const SizedBox(height: 8),
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
      margin: const EdgeInsets.all(16),
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

  // 2 -> '02'
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

  static const _joursFr = [
    'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
  ];

  static const _joursAr = [
    'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'
  ];

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();
    final texte = Theme.of(context).textTheme;
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
          Text(traduction.tr('meteoKebili'), style: texte.titleMedium),

          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                '${meteo.temperature.toStringAsFixed(0)} °C',
                style: texte.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${traduction.tr('humiditeAir')} : ${meteo.humiditeAir} %",
                  ),
                  Text(
                    "${traduction.tr('vent')} : ${meteo.vent.toStringAsFixed(0)} km/h",
                  ),
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
                  SizedBox(
                    width: 95,
                    child: Text(
                          () {
                        final maintenant = DateTime.now();
                        final aujourdhui = DateTime(
                          maintenant.year,
                          maintenant.month,
                          maintenant.day,
                        );
                        final datePrevision = DateTime(
                          p.date.year,
                          p.date.month,
                          p.date.day,
                        );

                        final difference =
                            datePrevision.difference(aujourdhui).inDays;

                        if (difference == 0) {
                          return traduction.tr('aujourdhui');
                        }
                        if (difference == 1) {
                          return traduction.tr('demain');
                        }
                        if (difference == 2) {
                          return traduction.tr('apresDemain');
                        }

                        final index = p.date.weekday - 1;
                        return traduction.estArabe
                            ? _joursAr[index]
                            : _joursFr[index];
                      }(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

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

          Row(
            children: [
              Expanded(
                child: Text(
                  conseil,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.translate, color: Colors.green),
                tooltip: traduction.tr('traduireArabe'),
                onPressed: () {
                  context.read<TraductionProvider>().traduire(
                    conseil,
                    TranslateLanguage.french,
                    TranslateLanguage.arabic,
                  );
                },
              ),
            ],
          ),

          // Affichage de la date de mise à jour et de l'état hors ligne
          if (_libelleMiseAJour(traduction).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _libelleMiseAJour(traduction),
              style: texte.bodySmall,
            ),
          ],

          if (horsLigne)
            TextButton(
              onPressed: () => context.read<MeteoProvider>().charger(),
              child: Text(traduction.tr('reessayer')),
            ),

          Consumer<TraductionProvider>(
            builder: (context, trad, _) {
              if (trad.etat == EtatTraduction.traductionEnCours) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trad.tr('traductionEnCours'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (trad.etat == EtatTraduction.succes &&
                  trad.texteTraduit.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trad.texteTraduit,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              }

              if (trad.etat == EtatTraduction.erreur &&
                  trad.erreur.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    trad.erreur,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
