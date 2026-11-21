import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:agrismart/providers/traduction_provider.dart';

class AProposPage extends StatefulWidget {
  const AProposPage({super.key});

  @override
  State<AProposPage> createState() => _AProposPageState();
}

class _AProposPageState extends State<AProposPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traductionProvider = context.watch<TraductionProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(traductionProvider.tr('aPropos'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AgriSmart',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(traductionProvider.tr('version')),
            const SizedBox(height: 16),
            Text(traductionProvider.tr('descriptionApp')),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.g_translate, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  traductionProvider.tr('traductionTitre'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: traductionProvider.tr('saisirTexte'),
                hintText: 'Ex: Bienvenue sur AgriSmart',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.translate),
              label: Text(traductionProvider.tr('traduireArabe')),
              onPressed: (traductionProvider.etat == EtatTraduction.chargementModele ||
                      traductionProvider.etat == EtatTraduction.traductionEnCours)
                  ? null
                  : () {
                      final texte = _controller.text.trim();
                      if (texte.isNotEmpty) {
                        context.read<TraductionProvider>().traduire(
                              texte,
                              TranslateLanguage.french,
                              TranslateLanguage.arabic,
                            );
                      }
                    },
            ),
            const SizedBox(height: 12),
            if (traductionProvider.etat == EtatTraduction.traductionEnCours)
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(traductionProvider.tr('traductionEnCours')),
                ],
              )
            else if (traductionProvider.etat == EtatTraduction.succes &&
                traductionProvider.texteTraduit.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Text(
                  traductionProvider.texteTraduit,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              )
            else if (traductionProvider.etat == EtatTraduction.erreur &&
                traductionProvider.erreur.isNotEmpty)
              Text(
                traductionProvider.erreur,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 32),
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(traductionProvider.tr('retour')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}