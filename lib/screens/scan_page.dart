import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/intervention.dart';
import 'package:agrismart/models/intrant.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/interventions_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/services/scan_service.dart';
import 'package:agrismart/theme/app_theme.dart';

/// Scan terrain : 1) QR de la parcelle, 2) code-barres du produit
/// -> contrôle de compatibilité + délai avant récolte -> journal d'intervention.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.code128,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  Zone? _zone;
  Intrant? _intrant;
  String? _codeInconnu;
  String? _derniereValeur;
  DateTime _dernierScan = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texte)));
  }

  /// Point d'entrée unique : caméra, photo de la galerie ou saisie manuelle.
  void _traiter(String brut) {
    if (!mounted) return;
    final valeur = brut.trim();
    if (valeur.isEmpty) return;

    // Évite de retraiter le même code plusieurs fois de suite.
    final maintenant = DateTime.now();
    if (valeur == _derniereValeur &&
        maintenant.difference(_dernierScan) < const Duration(seconds: 2)) {
      return;
    }
    _derniereValeur = valeur;
    _dernierScan = maintenant;

    final traduction = context.read<TraductionProvider>();
    final nomZone = CodeZone.decoder(valeur);

    if (nomZone != null) {
      final zones = context.read<ZonesProvider>().zones.where((z) => z.nom == nomZone);
      if (zones.isEmpty) {
        _message(traduction.tr('qrInconnu'));
        return;
      }
      HapticFeedback.mediumImpact();
      setState(() {
        _zone = zones.first;
        _codeInconnu = null;
      });
      return;
    }

    final intrant = trouverIntrant(valeur);
    HapticFeedback.mediumImpact();
    setState(() {
      _intrant = intrant;
      _codeInconnu = intrant == null ? valeur : null;
    });
  }

  Future<void> _depuisPhoto() async {
    final traduction = context.read<TraductionProvider>();
    final fichier = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (fichier == null) return;
    try {
      final capture = await _controller.analyzeImage(fichier.path);
      final valeur = capture?.barcodes
          .map((b) => b.rawValue)
          .whereType<String>()
          .firstOrNull;
      if (!mounted) return;
      if (valeur == null) {
        _message(traduction.tr('aucunCodeTrouve'));
      } else {
        _traiter(valeur);
      }
    } catch (_) {
      if (mounted) _message(traduction.tr('aucunCodeTrouve'));
    }
  }

  Future<void> _saisirCode() async {
    final saisi = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogueCode(),
    );
    if (saisi != null) _traiter(saisi);
  }

  void _enregistrer({required bool culturePrevue}) {
    final zone = _zone;
    final intrant = _intrant;
    if (zone == null || intrant == null) return;
    context.read<InterventionsProvider>().ajouter(
      Intervention(
        zoneNom: zone.nom,
        intrant: intrant,
        date: DateTime.now(),
        culturePrevue: culturePrevue,
      ),
    );
    _message(context.read<TraductionProvider>().tr('interventionEnregistree'));
    // On garde la zone : on peut enchaîner plusieurs produits sur la même parcelle.
    setState(() {
      _intrant = null;
      _codeInconnu = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(traduction.tr('scanTitre')),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            tooltip: traduction.tr('lampe'),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: traduction.tr('depuisPhoto'),
            onPressed: _depuisPhoto,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            tooltip: traduction.tr('saisirCode'),
            onPressed: _saisirCode,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    for (final b in capture.barcodes) {
                      final v = b.rawValue;
                      if (v != null) {
                        _traiter(v);
                        break;
                      }
                    }
                  },
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 160,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: _panneau(context, traduction),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _panneau(BuildContext context, TraductionProvider tr) {
    final zone = _zone;
    final intrant = _intrant;
    final restriction = zone == null
        ? null
        : context.watch<InterventionsProvider>().recolteAutoriseeLe(zone.nom);

    return [
      // Étape 1 : zone
      Card(
        child: ListTile(
          leading: Icon(zone == null ? Icons.qr_code_2 : Icons.check_circle,
              color: zone == null ? null : AppTheme.succes),
          title: Text(zone == null ? tr.tr('scanEtape1') : zone.nom),
          subtitle: zone == null
              ? null
              : Text(
            '${zone.culture} · ${zone.humidite.toStringAsFixed(0)} % · '
                '${zone.besoinIrrigation ? tr.tr('besoinIrrigation') : tr.tr('solCorrect')}'
                '${restriction == null ? '' : '\n${tr.tr('recolteDeconseilleeJusquau')} ${formaterDate(restriction)}'}',
          ),
          isThreeLine: restriction != null,
        ),
      ),
      // Étape 2 : produit
      Card(
        child: ListTile(
          leading: Icon(intrant == null ? Icons.barcode_reader : Icons.check_circle,
              color: intrant == null ? null : AppTheme.succes),
          title: Text(intrant == null ? tr.tr('scanEtape2') : intrant.nom),
          subtitle: intrant == null
              ? (_codeInconnu == null
              ? null
              : Text('${tr.tr('produitInconnu')} ($_codeInconnu)'))
              : Text('${tr.tr('dosage')} : ${intrant.dosage}\n'
              '${tr.tr('delaiAvantRecolte')} : ${intrant.delaiAvantRecolteJours} ${tr.tr('jours')}'),
          isThreeLine: intrant != null,
        ),
      ),
      if (zone != null && intrant != null) ..._verdict(tr, zone, intrant),
      const SizedBox(height: 8),
      Text(
        tr.tr('avertissementScan'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }

  List<Widget> _verdict(TraductionProvider tr, Zone zone, Intrant intrant) {
    final compatible = intrantConvientA(intrant, zone.culture);
    final couleur = compatible ? AppTheme.succes : AppTheme.echec;
    final fin = DateTime.now().add(Duration(days: intrant.delaiAvantRecolteJours));

    return [
      Card(
        color: couleur.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(compatible ? Icons.verified : Icons.warning_amber_rounded, color: couleur),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  compatible
                      ? '${tr.tr('compatible')}\n'
                      '${intrant.delaiAvantRecolteJours > 0 ? '${tr.tr('recolteAPartirDu')} ${formaterDate(fin)}' : tr.tr('aucunDelai')}'
                      : tr.tr('incompatible'),
                  style: TextStyle(color: couleur, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: () => _enregistrer(culturePrevue: compatible),
        icon: const Icon(Icons.save),
        label: Text(compatible ? tr.tr('enregistrerIntervention') : tr.tr('enregistrerMalgre')),
        style: compatible ? null : FilledButton.styleFrom(backgroundColor: AppTheme.echec),
      ),
    ];
  }
}

/// Saisie manuelle d'un code (étiquette abîmée, émulateur sans caméra...).
class _DialogueCode extends StatefulWidget {
  const _DialogueCode();

  @override
  State<_DialogueCode> createState() => _DialogueCodeState();
}

class _DialogueCodeState extends State<_DialogueCode> {
  final TextEditingController _champ = TextEditingController();

  @override
  void dispose() {
    _champ.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.watch<TraductionProvider>();
    return AlertDialog(
      title: Text(tr.tr('saisirCode')),
      content: TextField(
        controller: _champ,
        autofocus: true,
        decoration: InputDecoration(labelText: tr.tr('codeLabel')),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr.tr('annuler'))),
        FilledButton(
          onPressed: () => Navigator.pop(context, _champ.text),
          child: Text(tr.tr('valider')),
        ),
      ],
    );
  }
}
