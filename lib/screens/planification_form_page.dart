import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/planification.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';

class PlanificationFormPage extends StatefulWidget {
  final PlanificationIrrigation? planification;

  const PlanificationFormPage({super.key, this.planification});

  @override
  State<PlanificationFormPage> createState() => _PlanificationFormPageState();
}

class _PlanificationFormPageState extends State<PlanificationFormPage> {
  final _formKey = GlobalKey<FormState>();

  String? _zoneNomChoisie;
  late DateTime _dateSelectionnee;
  late TimeOfDay _heureSelectionnee;
  late int _dureeMinutes;
  late RepetitionIrrigation _repetition;
  late bool _estActive;

  bool get _modeEdition => widget.planification != null;

  @override
  void initState() {
    super.initState();
    final p = widget.planification;
    if (p != null) {
      _zoneNomChoisie = p.zoneNom;
      _dateSelectionnee = p.dateHeure;
      _heureSelectionnee = TimeOfDay.fromDateTime(p.dateHeure);
      _dureeMinutes = p.dureeMinutes;
      _repetition = p.repetition;
      _estActive = p.estActive;
    } else {
      final maintenant = DateTime.now();
      _dateSelectionnee = maintenant;
      _heureSelectionnee = TimeOfDay(hour: (maintenant.hour + 1) % 24, minute: 0);
      _dureeMinutes = 30;
      _repetition = RepetitionIrrigation.uneFois;
      _estActive = true;
    }
  }

  Future<void> _choisirDate() async {
    final nouvelleDate = await showDatePicker(
      context: context,
      initialDate: _dateSelectionnee,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (nouvelleDate != null) {
      setState(() {
        _dateSelectionnee = DateTime(
          nouvelleDate.year,
          nouvelleDate.month,
          nouvelleDate.day,
          _dateSelectionnee.hour,
          _dateSelectionnee.minute,
        );
      });
    }
  }

  Future<void> _choisirHeure() async {
    final nouvelleHeure = await showTimePicker(
      context: context,
      initialTime: _heureSelectionnee,
    );
    if (nouvelleHeure != null) {
      setState(() {
        _heureSelectionnee = nouvelleHeure;
        _dateSelectionnee = DateTime(
          _dateSelectionnee.year,
          _dateSelectionnee.month,
          _dateSelectionnee.day,
          nouvelleHeure.hour,
          nouvelleHeure.minute,
        );
      });
    }
  }

  void _soumettre() {
    if (!_formKey.currentState!.validate()) return;
    if (_zoneNomChoisie == null || _zoneNomChoisie!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une parcelle')),
      );
      return;
    }

    final dateFinale = DateTime(
      _dateSelectionnee.year,
      _dateSelectionnee.month,
      _dateSelectionnee.day,
      _heureSelectionnee.hour,
      _heureSelectionnee.minute,
    );

    final p = PlanificationIrrigation(
      id: widget.planification?.id,
      zoneNom: _zoneNomChoisie!,
      dateHeure: dateFinale,
      dureeMinutes: _dureeMinutes,
      repetition: _repetition,
      estActive: _estActive,
    );

    Navigator.pop(context, p);
  }

  String _libelleRepetition(RepetitionIrrigation r, TraductionProvider traduction) {
    switch (r) {
      case RepetitionIrrigation.uneFois:
        return traduction.tr('uneFois');
      case RepetitionIrrigation.quotidienne:
        return traduction.tr('quotidienne');
      case RepetitionIrrigation.hebdomadaire:
        return traduction.tr('hebdomadaire');
    }
  }

  static String _deux(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();
    final zones = context.watch<ZonesProvider>().zones;
    final nomsParcelles = zones.map((z) => z.nom).toList();

    if (_zoneNomChoisie == null && nomsParcelles.isNotEmpty) {
      _zoneNomChoisie = nomsParcelles.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _modeEdition ? traduction.tr('modifierPlanification') : traduction.tr('nouvellePlanification'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Choix de la parcelle
              DropdownButtonFormField<String>(
                initialValue: nomsParcelles.contains(_zoneNomChoisie) ? _zoneNomChoisie : (nomsParcelles.isNotEmpty ? nomsParcelles.first : null),
                decoration: InputDecoration(
                  labelText: traduction.tr('choisirParcelle'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.grass),
                ),
                items: nomsParcelles
                    .map((nom) => DropdownMenuItem(
                          value: nom,
                          child: Text(nom),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _zoneNomChoisie = val);
                },
                validator: (val) => val == null || val.isEmpty ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 16),

              // Date et Heure
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _choisirDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        '${_deux(_dateSelectionnee.day)}/${_deux(_dateSelectionnee.month)}/${_dateSelectionnee.year}',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _choisirHeure,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        '${_deux(_heureSelectionnee.hour)}:${_deux(_heureSelectionnee.minute)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Durée (en minutes)
              DropdownButtonFormField<int>(
                initialValue: _dureeMinutes,
                decoration: InputDecoration(
                  labelText: traduction.tr('dureeMinutes'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.timer_outlined),
                ),
                items: [15, 30, 45, 60, 90, 120]
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text('$m min'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _dureeMinutes = val);
                },
              ),
              const SizedBox(height: 16),

              // Répétition
              DropdownButtonFormField<RepetitionIrrigation>(
                initialValue: _repetition,
                decoration: InputDecoration(
                  labelText: traduction.tr('repetition'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.repeat),
                ),
                items: RepetitionIrrigation.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_libelleRepetition(r, traduction)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _repetition = val);
                },
              ),
              const SizedBox(height: 16),

              // Statut Actif
              SwitchListTile(
                title: Text(traduction.tr('actives')),
                value: _estActive,
                onChanged: (val) => setState(() => _estActive = val),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _soumettre,
                icon: const Icon(Icons.save),
                label: Text(traduction.tr('enregistrer')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
