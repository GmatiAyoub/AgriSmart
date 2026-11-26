import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';

class AProposPage extends StatelessWidget {
  const AProposPage({super.key});

  @override
  Widget build(BuildContext context) {
    final traductionProvider = context.watch<TraductionProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(traductionProvider.tr('aPropos'))),
      body: Padding(
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
