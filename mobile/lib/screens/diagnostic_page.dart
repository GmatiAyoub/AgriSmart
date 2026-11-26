import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/diagnostic_plante.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/services/diagnostic_service.dart';

/// Diagnostic préliminaire d'une plante à partir d'une photo.
class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({super.key});

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  final DiagnosticService _service = DiagnosticService();
  final ImagePicker _picker = ImagePicker();

  File? _photo;
  DiagnosticPlante? _resultat;
  String? _cultureChoisie;
  bool _chargement = false;

  bool get _mobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _choisir(ImageSource source) async {
    final fichier = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (fichier == null) return;

    setState(() {
      _photo = File(fichier.path);
      _resultat = null;
      _chargement = true;
    });

    try {
      final r = await _service.analyser(_photo!, cultureIndiquee: _cultureChoisie);
      if (!mounted) return;
      setState(() => _resultat = r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<TraductionProvider>();
    final cultures = context
        .read<ZonesProvider>()
        .zones
        .map((z) => z.culture)
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(tr.tr('diagTitre')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(tr.tr('diagAide')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(tr.tr('cultureOptionnelle'))),
              DropdownButton<String?>(
                value: _cultureChoisie,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(tr.tr('detectionAuto')),
                  ),
                  ...cultures.map(
                        (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                  ),
                ],
                onChanged: _chargement
                    ? null
                    : (v) => setState(() => _cultureChoisie = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_mobile) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                    _chargement ? null : () => _choisir(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(tr.tr('camera')),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                  _chargement ? null : () => _choisir(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(tr.tr('galerie')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_photo!, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 16),
          if (_chargement)
            const Center(child: CircularProgressIndicator())
          else if (_resultat != null)
            _carteResultat(context, tr, _resultat!),
          const SizedBox(height: 12),
          _avertissement(context, tr),
        ],
      ),
    );
  }

  Widget _carteResultat(
      BuildContext context, TraductionProvider tr, DiagnosticPlante d) {
    final theme = Theme.of(context);
    final couleurEtat = switch (d.etat) {
      EtatVisuel.sain => Colors.green.shade700,
      EtatVisuel.anomalie => theme.colorScheme.error,
      EtatVisuel.indetermine => theme.colorScheme.outline,
    };
    final libelleEtat = switch (d.etat) {
      EtatVisuel.sain => tr.tr('etatSain'),
      EtatVisuel.anomalie => tr.tr('etatAnomalie'),
      EtatVisuel.indetermine => tr.tr('etatIndetermine'),
    };
    final libelleNiveau = switch (d.niveau) {
      NiveauConfiance.faible => tr.tr('confFaible'),
      NiveauConfiance.moyen => tr.tr('confMoyen'),
      NiveauConfiance.eleve => tr.tr('confEleve'),
    };
    final diagnostics = switch (d.etat) {
      EtatVisuel.anomalie => [tr.tr('diagAno1'), tr.tr('diagAno2'), tr.tr('diagAno3')],
      EtatVisuel.sain => [tr.tr('diagSain1'), tr.tr('diagSain2')],
      EtatVisuel.indetermine => [tr.tr('diagInd1')],
    };
    final recommandations = switch (d.etat) {
      EtatVisuel.anomalie => [tr.tr('recoAno1'), tr.tr('recoAno2'), tr.tr('recoAno3')],
      EtatVisuel.sain => [tr.tr('recoSain1'), tr.tr('recoSain2')],
      EtatVisuel.indetermine => [tr.tr('recoInd1'), tr.tr('recoInd2')],
    };

    final culture = d.culture == null
        ? tr.tr('cultureNonIdentifiee')
        : d.cultureIndiquee
        ? '${d.culture} (${tr.tr('cultureIndiquee')})'
        : d.culture!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tr.tr('cultureDetectee')} : $culture',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${tr.tr('etatVisuel')} : '),
                Flexible(
                  child: Text(
                    libelleEtat,
                    style: TextStyle(
                        color: couleurEtat, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${tr.tr('niveauConfiance')} : $libelleNiveau (${(d.confiance * 100).round()} %)',
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: d.confiance, minHeight: 8),
            const Divider(height: 28),
            Text(tr.tr('diagPrelim'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            ..._puces(diagnostics),
            const SizedBox(height: 12),
            Text(tr.tr('recommandations'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            ..._puces(recommandations),
          ],
        ),
      ),
    );
  }

  List<Widget> _puces(List<String> lignes) => lignes
      .map((t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(child: Text(t)),
      ],
    ),
  ))
      .toList();

  Widget _avertissement(BuildContext context, TraductionProvider tr) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: c.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr.tr('avertissementPhoto'),
              style: TextStyle(color: c.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
