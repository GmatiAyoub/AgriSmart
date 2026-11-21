import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/traduction_provider.dart';

class ZoneForm extends StatefulWidget {
  final Zone? zone;
  final void Function(Zone) onEnregistrer;
  final List<String> nomsExistants;

  const ZoneForm({
    super.key,
    this.zone,
    required this.onEnregistrer,
    required this.nomsExistants,
  });

  @override
  State<ZoneForm> createState() => _ZoneFormState();
}

class _ZoneFormState extends State<ZoneForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _cultureCtrl = TextEditingController();
  final _humiditeCtrl = TextEditingController();
  final _seuilCtrl = TextEditingController();

  bool get _modeEdition => widget.zone != null;

  @override
  void initState() {
    super.initState();
    final zone = widget.zone;
    if (zone != null) {
      _nomCtrl.text = zone.nom;
      _cultureCtrl.text = zone.culture;
      _seuilCtrl.text = _formater(zone.seuil);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _cultureCtrl.dispose();
    _humiditeCtrl.dispose();
    _seuilCtrl.dispose();
    super.dispose();
  }

  String _formater(double n) {
    return n % 1 == 0 ? n.toStringAsFixed(0) : n.toString();
  }

  double? _lireNombre(String? texte) {
    return double.tryParse((texte ?? '').trim().replaceAll(',', '.'));
  }

  String? _validatorTexte(String? valeur) {
    if (valeur == null || valeur.trim().length < 2) {
      return 'Ce champ est obligatoire (2 caractères min)';
    }
    return null;
  }

  String? _validatorNom(String? valeur) {
    final erreurBase = _validatorTexte(valeur);
    if (erreurBase != null) return erreurBase;

    final nomSaisi = valeur!.trim().toLowerCase();
    final existeDeja = widget.nomsExistants
        .map((n) => n.toLowerCase())
        .contains(nomSaisi);

    if (existeDeja) {
      return 'Ce nom existe déjà';
    }
    return null;
  }

  String? _validatorPourcentage(String? valeur) {
    final nombre = _lireNombre(valeur);
    if (nombre == null) {
      return 'Veuillez saisir un nombre valide';
    }
    if (nombre < 0 || nombre > 100) {
      return 'Le nombre doit être entre 0 et 100';
    }
    return null;
  }

  void _soumettre() {
    if (!_formKey.currentState!.validate()) return;

    final nom = _nomCtrl.text.trim();
    final culture = _cultureCtrl.text.trim();
    final seuil = _lireNombre(_seuilCtrl.text)!;

    final humidite = _modeEdition
        ? widget.zone!.humidite
        : _lireNombre(_humiditeCtrl.text)!;

    final zone = Zone(
      nom,
      culture,
      humidite,
      seuil,
      vanneOuverte: _modeEdition ? widget.zone!.vanneOuverte : false,
    );

    widget.onEnregistrer(zone);
  }

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _modeEdition ? traduction.tr('modifierZone') : traduction.tr('nouvelleZone'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomCtrl,
              decoration: InputDecoration(
                labelText: traduction.tr('nomZone'),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: _validatorNom,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cultureCtrl,
              decoration: InputDecoration(
                labelText: traduction.tr('culture'),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: _validatorTexte,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_modeEdition)
                  Expanded(
                    child: TextFormField(
                      controller: _humiditeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Humidité (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validatorPourcentage,
                    ),
                  ),
                if (!_modeEdition) const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _seuilCtrl,
                    decoration: InputDecoration(
                      labelText: traduction.tr('seuilPercent'),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _validatorPourcentage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _soumettre,
              child: Text(_modeEdition ? traduction.tr('enregistrer') : traduction.tr('enregistrer')),
            ),
          ],
        ),
      ),
    );
  }
}