import 'package:flutter/material.dart';

class AProposPage extends StatelessWidget {
  const AProposPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
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
            const Text('Version 1.0.0'),
            const SizedBox(height: 16),
            const Text(
              "Application de suivi des zones d'une exploitation agricole, développée dans le cadre de l'atelier Framework Cross-Platform à l'ISET Kébili.",
            ),
            const SizedBox(height: 32),
            Center(
              child: FilledButton(
                onPressed: () => Navigator.pop(context), // Ferme la page
                child: const Text('Retour'),
              ),
            )
          ],
        ),
      ),
    );
  }
}