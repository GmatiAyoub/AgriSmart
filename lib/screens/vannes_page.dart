import 'package:flutter/material.dart';
import 'package:agrismart/models/parcelle_api.dart';
import 'package:agrismart/models/vanne.dart';
import 'package:agrismart/screens/vanne_form_page.dart';
import 'package:agrismart/services/api_client.dart';
import 'package:agrismart/services/parcelle_service.dart';
import 'package:agrismart/services/vanne_service.dart';

class _VanneItem {
  final Vanne vanne;
  final String nomParcelle;

  const _VanneItem({required this.vanne, required this.nomParcelle});
}

class VannesPage extends StatefulWidget {
  final List<String> nomsZones; // parcelles existantes
  final String? zoneFiltre; // si renseignee : seulement les vannes de cette parcelle

  const VannesPage({super.key, required this.nomsZones, this.zoneFiltre});

  @override
  State<VannesPage> createState() => _VannesPageState();
}

class _VannesPageState extends State<VannesPage> {
  final _service = VanneService();
  final _parcelleService = ParcelleService();
  late Future<List<_VanneItem>> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<List<_VanneItem>> _charger() async {
    final parcelles = await _parcelleService.lister();
    final parcellesMap = {for (final p in parcelles) p.id: p.nom};
    final toutes = await _service.lister();

    final items = toutes.map((v) {
      final nomParcelle = v.parcelleId != null ? (parcellesMap[v.parcelleId] ?? '') : '';
      return _VanneItem(vanne: v, nomParcelle: nomParcelle);
    }).toList();

    final zone = widget.zoneFiltre;
    if (zone == null) return items;
    return items
        .where((i) => ParcelleApi.cle(i.nomParcelle) == ParcelleApi.cle(zone))
        .toList();
  }

  void _recharger() {
    setState(() => _futur = _charger());
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  // Execute une action reseau, affiche l'erreur, puis recharge la liste
  Future<void> _executer(Future<void> Function() action, String succes) async {
    try {
      await action();
      if (!mounted) return;
      _message(succes);
    } on ApiException catch (e) {
      if (!mounted) return;
      _message(e.message);
    }
    if (mounted) _recharger();
  }

  Future<void> _ajouter() async {
    final result = await Navigator.push<VanneFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => VanneFormPage(
          nomsZones: widget.nomsZones,
          zoneFixe: widget.zoneFiltre,
        ),
      ),
    );
    if (result == null) return;
    await _executer(() async {
      final parcelle = await _parcelleService.assurer(result.zone);
      await _service.creer(result.nom, parcelle.id);
    }, 'Vanne ajoutée');
  }

  Future<void> _modifier(_VanneItem item) async {
    final result = await Navigator.push<VanneFormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => VanneFormPage(
          nomInitial: item.vanne.nom,
          nomsZones: widget.nomsZones,
          zoneFixe: item.nomParcelle.isNotEmpty ? item.nomParcelle : widget.zoneFiltre,
        ),
      ),
    );
    if (result == null) return;
    await _executer(() => _service.renommer(item.vanne.id, result.nom), 'Vanne modifiée');
  }

  // Bouton logique : ouvrir / fermer
  Future<void> _basculer(Vanne vanne, bool ouverte) async {
    await _executer(
      () => _service.commander(vanne.id, ouvrir: ouverte),
      ouverte ? 'Vanne ouverte' : 'Vanne fermée',
    );
  }

  Future<void> _confirmerSuppression(Vanne vanne) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la vanne ?'),
        content: Text(vanne.nom),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme != true) return;
    await _executer(() => _service.supprimer(vanne.id), 'Vanne supprimée');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zoneFiltre == null
            ? 'Vannes'
            : 'Vannes · ${widget.zoneFiltre}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouter,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<_VanneItem>>(
        future: _futur,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final erreur = snapshot.error;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(erreur is ApiException
                      ? erreur.message
                      : 'Erreur inattendue'),
                  const SizedBox(height: 8),
                  FilledButton(
                      onPressed: _recharger, child: const Text('Réessayer')),
                ],
              ),
            );
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Aucune vanne pour le moment'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              _recharger();
              await _futur;
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = items[i];
                final v = item.vanne;
                final zone = item.nomParcelle;
                return ListTile(
                  leading: Icon(
                    Icons.water_drop,
                    color: v.ouverte ? Colors.blue : Colors.grey,
                  ),
                  title: Text(v.nom),
                  subtitle: Text(
                      '${zone.isEmpty ? '-' : zone} · ${v.ouverte ? 'Ouverte' : 'Fermée'}'),
                  onTap: () => _modifier(item),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: v.ouverte,
                        onChanged: (val) => _basculer(v, val),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmerSuppression(v),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
