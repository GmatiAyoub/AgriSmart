import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/widgets/zone_form.dart';

class ZoneFormPage extends StatelessWidget {
  final Zone? zone;
  final List<String> nomsExistants;

  const ZoneFormPage({
    super.key,
    this.zone,
    required this.nomsExistants,
  });

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();
    final edition = zone != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(edition ? traduction.tr('modifierZone') : traduction.tr('nouvelleZone')),
      ),
      body: SingleChildScrollView(
        child: ZoneForm(
          zone: zone,
          nomsExistants: nomsExistants,
          onEnregistrer: (zoneEnregistree) {
            Navigator.pop(context, zoneEnregistree);
          },
        ),
      ),
    );
  }
}
