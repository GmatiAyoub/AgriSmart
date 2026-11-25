import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/theme/app_theme.dart';

class ZoneDetailPage extends StatefulWidget {
  final Zone zone;
  final List<String> nomsAutres;

  const ZoneDetailPage({
    super.key,
    required this.zone,
    this.nomsAutres = const [],
  });

  @override
  State<ZoneDetailPage> createState() => _ZoneDetailPageState();
}

class _ZoneDetailPageState extends State<ZoneDetailPage> {
  late Zone _zoneActuelle;

  @override
  void initState() {
    super.initState();
    _zoneActuelle = widget.zone;
  }

  Future<void> _modifier(BuildContext context) async {
    final nouvelle = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (_) => ZoneFormPage(
          zone: _zoneActuelle,
          nomsExistants: widget.nomsAutres,
        ),
      ),
    );

    if (nouvelle == null || !context.mounted) return;
    setState(() {
      _zoneActuelle = nouvelle;
    });
    Navigator.pop(context, nouvelle);
  }

  Future<void> _basculerVanne(BuildContext context) async {
    final provider = context.read<ZonesProvider>();
    final nouvelleValeur = !_zoneActuelle.vanneOuverte;
    await provider.changerEtatVanne(_zoneActuelle, nouvelleValeur);
    setState(() {
      _zoneActuelle = _zoneActuelle.copyWith(vanneOuverte: nouvelleValeur);
    });
  }

  @override
  Widget build(BuildContext context) {
    final traduction = context.watch<TraductionProvider>();
    final couleur = _zoneActuelle.besoinIrrigation ? AppTheme.echec : AppTheme.succes;
    final longueur = _zoneActuelle.culture.length < 4 ? _zoneActuelle.culture.length : 4;
    final texte = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_zoneActuelle.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: traduction.tr('modifierZone'),
            onPressed: () => _modifier(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: couleur.withValues(alpha: 0.2),
                child: Text(
                  _zoneActuelle.culture.substring(0, longueur),
                  style: TextStyle(color: couleur, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_zoneActuelle.nom, style: texte.headlineSmall),
                    Text(_zoneActuelle.culture, style: texte.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Center(
            child: Text(
              '${_zoneActuelle.humidite.toStringAsFixed(0)} %',
              style: texte.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _zoneActuelle.humidite / 100,
            color: couleur,
            backgroundColor: couleur.withValues(alpha: 0.2),
            minHeight: 10,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _zoneActuelle.besoinIrrigation ? traduction.tr('besoinIrrigation') : traduction.tr('solCorrect'),
              style: TextStyle(
                color: couleur,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.water_drop),
                  title: Text(traduction.tr('humActuelle')),
                  trailing: Text('${_zoneActuelle.humidite.toStringAsFixed(0)} %'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag),
                  title: Text(traduction.tr('seuilIrrigation')),
                  trailing: Text('${_zoneActuelle.seuil.toStringAsFixed(0)} %'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(
                    _zoneActuelle.vanneOuverte ? Icons.water_drop : Icons.water_drop_outlined,
                    color: _zoneActuelle.vanneOuverte ? Colors.blue : Colors.grey,
                  ),
                  title: Text(traduction.tr('vanne')),
                  subtitle: Text(
                    _zoneActuelle.vanneOuverte ? traduction.tr('vanneOuverte') : traduction.tr('vanneFermee'),
                  ),
                  value: _zoneActuelle.vanneOuverte,
                  onChanged: (val) => _basculerVanne(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: () => _modifier(context),
            icon: const Icon(Icons.edit),
            label: Text(traduction.tr('modifierCetteZone')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
