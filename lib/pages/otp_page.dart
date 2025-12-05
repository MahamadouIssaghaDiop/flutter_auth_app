import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'home_page.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;
  final AuthService auth;

  const OtpPage({super.key, required this.verificationId, required this.auth});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController codeCtrl = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _verify() async {
    final code = codeCtrl.text.trim();

    if (code.length != 6) {
      _showError('Le code doit contenir 6 chiffres');
      return;
    }

    setState(() => loading = true);

    try {
      await widget.auth.signInWithSmsCode(
        verificationId: widget.verificationId,
        smsCode: code,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (r) => false,
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification SMS'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            Text(
              'Entrez le code reçu par SMS',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Code à 6 chiffres',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: loading ? null : _verify,
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Vérifier'),
            ),
          ],
        ),
      ),
    );
  }
}
