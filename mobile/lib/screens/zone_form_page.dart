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
    this.nomsExistants = const [],
  });

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(zone == null ? traduction.tr('nouvelleZone') : traduction.tr('modifierZone')),
      ),
      body: SingleChildScrollView(
        child: ZoneForm(
          zone: zone,
          nomsExistants: nomsExistants,
          onEnregistrer: (nouvelle) => Navigator.pop(context, nouvelle),
        ),
      ),
    );
  }
}