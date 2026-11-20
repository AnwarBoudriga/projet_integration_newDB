import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoggedIn});
  final VoidCallback onLoggedIn;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pwd = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_id.text.trim().isEmpty || _pwd.text.isEmpty) {
      setState(() => _error = 'Identifiant et mot de passe requis.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Api.login(_id.text.trim(), _pwd.text);
      widget.onLoggedIn();
    } catch (e) {
      if (mounted) setState(() => _error = Api.errorMessage(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= 800;
        return Row(children: [
          if (wide)
            Expanded(
              flex: 4,
              child: Container(
                color: C.navy,
                padding: const EdgeInsets.all(40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Logo(dark: true),
                  const Spacer(),
                  Container(width: 40, height: 2, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text('Plateforme de Gestion de\nTests Psychotechniques',
                      style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w300, height: 1.3)),
                  const Spacer(),
                  const Row(children: [
                    Icon(Icons.vpn_key_outlined, size: 14, color: Colors.white54),
                    SizedBox(width: 8),
                    Text('Espace Super Administrateur', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ]),
                ]),
              ),
            ),
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Logo(),
                    const SizedBox(height: 28),
                    const Text('Connexion', style: TextStyle(fontSize: 26, color: C.navy)),
                    const SizedBox(height: 6),
                    const Text('Saisissez vos identifiants pour accéder au module Super Administrateur.',
                        style: TextStyle(fontSize: 13, color: C.muted)),
                    const SizedBox(height: 24),
                    LabeledField(label: 'Identifiant', controller: _id, hint: 'Saisir votre identifiant'),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Mot de passe',
                      controller: _pwd,
                      hint: 'Saisir votre mot de passe',
                      obscure: true,
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(label: 'Se connecter', loading: _loading, onPressed: _submit),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}
