import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/providers/traduction_provider.dart';
import 'package:agrismart/screens/inscription_page.dart';

String? validerEmail(String? valeur) {
  final v = (valeur ?? '').trim();
  if (v.isEmpty) return "L'email est obligatoire";
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  if (!ok) return 'Email invalide';
  return null;
}

String? validerMotDePasse(String? valeur) {
  if (valeur == null || valeur.isEmpty) return 'Le mot de passe est obligatoire';
  if (valeur.length < 6) return '6 caractères minimum';
  return null;
}

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  bool _masquer = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().connexion(_emailCtrl.text, _mdpCtrl.text);
  }

  Future<void> _motDePasseOublie() async {
    final traduction = context.read<TraductionProvider>();
    final email = _emailCtrl.text;
    if (validerEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(traduction.tr('saisirEmail'))),
      );
      return;
    }
    final ok =
    await context.read<AuthProvider>().reinitialiserMotDePasse(email);
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(traduction.tr('emailEnvoye'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final traduction = context.watch<TraductionProvider>();

    return Scaffold(
      appBar: AppBar(
        actions: [
          ActionChip(
            avatar: const Icon(Icons.language, size: 18),
            label: Text(traduction.estArabe ? 'FR' : 'عربي'),
            onPressed: () => context.read<TraductionProvider>().basculerLangue(),
          ),
          const SizedBox(width: 12),
        ],
      ),
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
                    const Icon(Icons.agriculture, size: 64),
                    const SizedBox(height: 8),
                    Text(
                      'AgriSmart',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),

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
                          icon: Icon(_masquer
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() => _masquer = !_masquer);
                          },
                        ),
                      ),
                      validator: validerMotDePasse,
                    ),

                    if (auth.erreur != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        auth.erreur!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 16),

                    FilledButton(
                      onPressed: auth.occupe ? null : _connecter,
                      child: auth.occupe
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(traduction.tr('connexion')),
                    ),

                    TextButton(
                      onPressed: auth.occupe ? null : _motDePasseOublie,
                      child: Text(traduction.tr('motDePasseOublie')),
                    ),

                    TextButton(
                      onPressed: auth.occupe
                          ? null
                          : () {
                        context.read<AuthProvider>().effacerErreur();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InscriptionPage(),
                          ),
                        );
                      },
                      child: Text(traduction.tr('pasDeCompte')),
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