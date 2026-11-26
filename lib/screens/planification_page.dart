import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/planification.dart';
import 'package:agrismart/providers/planification_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/screens/planification_form_page.dart';

class PlanificationPage extends StatelessWidget {
  const PlanificationPage({super.key});

  static String _deux(int n) => n.toString().padLeft(2, '0');

  String _formaterDate(DateTime dt) {
    return '${_deux(dt.day)}/${_deux(dt.month)}/${dt.year} ${_deux(dt.hour)}:${_deux(dt.minute)}';
  }

  String _libelleRepetition(RepetitionIrrigation r, TraductionProvider traduction) {
    switch (r) {
      case RepetitionIrrigation.quotidienne:
        return traduction.tr('quotidienne');
      case RepetitionIrrigation.hebdomadaire:
        return traduction.tr('hebdomadaire');
    }
  }

  void _message(BuildContext context, String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _ajouter(BuildContext context) async {
    final nouvelle = await Navigator.push<PlanificationIrrigation>(
      context,
      MaterialPageRoute(builder: (_) => const PlanificationFormPage()),
    );
    if (nouvelle == null || !context.mounted) return;
    final traduction = context.read<TraductionProvider>();
    final erreur = await context.read<PlanificationProvider>().ajouter(nouvelle);
    if (!context.mounted) return;
    _message(context, erreur ?? traduction.tr('planificationAjoutee'));
  }

  Future<void> _modifier(BuildContext context, PlanificationIrrigation item) async {
    final modifiee = await Navigator.push<PlanificationIrrigation>(
      context,
      MaterialPageRoute(builder: (_) => PlanificationFormPage(planification: item)),
    );
    if (modifiee == null || !context.mounted) return;
    final traduction = context.read<TraductionProvider>();
    final erreur = await context.read<PlanificationProvider>().modifier(item, modifiee);
    if (!context.mounted) return;
    _message(context, erreur ?? traduction.tr('planificationModifiee'));
  }

  Future<void> _supprimer(BuildContext context, PlanificationIrrigation item) async {
    final traduction = context.read<TraductionProvider>();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(traduction.tr('supprimerPlanification')),
        content: Text('${item.zoneNom} - ${_formaterDate(item.dateHeure)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(traduction.tr('annuler'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(traduction.tr('supprimer'))),
        ],
      ),
    );
    if (confirme != true || !context.mounted) return;
    final erreur = await context.read<PlanificationProvider>().supprimer(item);
    if (!context.mounted) return;
    _message(context, erreur ?? traduction.tr('planificationSupprimee'));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanificationProvider>();
    final list = provider.planifications;
    final traduction = context.watch<TraductionProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(traduction.tr('planification')),
        actions: [
          ActionChip(
            avatar: const Icon(Icons.language, size: 18),
            label: Text(traduction.estArabe ? 'FR' : 'عربي'),
            onPressed: () => context.read<TraductionProvider>().basculerLangue(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ajouter(context),
        icon: const Icon(Icons.add),
        label: Text(traduction.tr('nouvellePlanification')),
      ),
      body: Column(
        children: [
          // Carte résumé du calendrier
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                const Icon(Icons.event_available, size: 36, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        traduction.tr('planifications'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${provider.nombreActives}/${provider.nombre} ${traduction.tr("actives")}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    traduction.tr('aucunePlanification'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: item.estActive
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.grey.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.water_drop,
                                color: item.estActive ? Colors.green : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.zoneNom,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${item.dureeMinutes} min',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(_formaterDate(item.dateHeure), style: const TextStyle(fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '(${_libelleRepetition(item.repetition, traduction)})',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Switch(
                                  value: item.estActive,
                                  onChanged: (_) async {
                                    final erreur = await provider.basculerEtat(item);
                                    if (erreur != null && context.mounted) {
                                      _message(context, erreur);
                                    }
                                  },
                                ),
                                Text(
                                  item.estActive ? traduction.tr('actives') : 'Inactif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: item.estActive ? Colors.green : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: traduction.tr('modifierPlanification'),
                                  onPressed: () => _modifier(context, item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  tooltip: traduction.tr('supprimerPlanification'),
                                  onPressed: () => _supprimer(context, item),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
