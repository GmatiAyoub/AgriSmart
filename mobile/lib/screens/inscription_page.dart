import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/screens/connexion_page.dart'
    show validerEmail, validerMotDePasse;

class InscriptionPage extends StatefulWidget {
  const InscriptionPage({super.key});

  @override
  State<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends State<InscriptionPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confirmationCtrl = TextEditingController();

  bool _masquer = true;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    _confirmationCtrl.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await context.read<AuthProvider>().inscription(
      _nomCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _mdpCtrl.text,
    );

    if (ok && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final traduction = context.watch<TraductionProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(traduction.tr('inscription'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _nomCtrl,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: traduction.tr('nom'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (valeur) {
                        if (valeur == null || valeur.trim().isEmpty) {
                          return 'Veuillez saisir votre nom';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: traduction.tr('email'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: validerEmail,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _mdpCtrl,
                      obscureText: _masquer,
                      decoration: InputDecoration(
                        labelText: traduction.tr('motDePasse'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _masquer
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _masquer = !_masquer);
                          },
                        ),
                      ),
                      validator: validerMotDePasse,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmationCtrl,
                      obscureText: _masquer,
                      decoration: InputDecoration(
                        labelText: traduction.tr('confirmerMotDePasse'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (valeur) {
                        if (valeur == null || valeur.isEmpty) {
                          return 'Confirmez le mot de passe';
                        }

                        if (valeur != _mdpCtrl.text) {
                          return 'Les mots de passe sont différents';
                        }

                        return null;
                      },
                    ),

                    if (auth.erreur != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        auth.erreur!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 16),

                    FilledButton(
                      onPressed: auth.occupe ? null : _inscrire,
                      child: auth.occupe
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : Text(traduction.tr('creerMonCompte')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}