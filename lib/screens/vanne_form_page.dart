import 'package:flutter/material.dart';

class VanneFormResult {
  final String nom;
  final String zone;

  const VanneFormResult({required this.nom, required this.zone});
}

class VanneFormPage extends StatefulWidget {
  final String? nomInitial;
  final List<String> nomsZones;
  final String? zoneFixe;

  const VanneFormPage({
    super.key,
    this.nomInitial,
    required this.nomsZones,
    this.zoneFixe,
  });

  @override
  State<VanneFormPage> createState() => _VanneFormPageState();
}

class _VanneFormPageState extends State<VanneFormPage> {
  final _cle = GlobalKey<FormState>();
  late final TextEditingController _nom;
  String? _zone;

  @override
  void initState() {
    super.initState();
    _nom = TextEditingController(text: widget.nomInitial ?? '');
    final zone = widget.zoneFixe;
    if (zone != null && zone.isNotEmpty) {
      _zone = zone;
    } else if (widget.nomsZones.isNotEmpty) {
      _zone = widget.nomsZones.first;
    }
  }

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  void _valider() {
    if (!_cle.currentState!.validate()) return;
    if (_zone == null) return;
    Navigator.pop(
      context,
      VanneFormResult(
        nom: _nom.text.trim(),
        zone: _zone!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final edition = widget.nomInitial != null && widget.nomInitial!.isNotEmpty;
    final zones = [
      ...widget.nomsZones,
      if (_zone != null && !widget.nomsZones.contains(_zone)) _zone!,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(edition ? 'Modifier la vanne' : 'Ajouter une vanne'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _cle,
          child: ListView(
            children: [
              TextFormField(
                controller: _nom,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _zone,
                decoration: const InputDecoration(labelText: 'Parcelle'),
                items: [
                  for (final z in zones)
                    DropdownMenuItem(value: z, child: Text(z)),
                ],
                onChanged: widget.zoneFixe != null
                    ? null
                    : (v) => setState(() => _zone = v),
                validator: (v) => v == null ? 'Choisir une parcelle' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _valider,
                child: Text(edition ? 'Enregistrer' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
