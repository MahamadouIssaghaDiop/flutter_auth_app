import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'otp_page.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthService auth = AuthService();
  final TextEditingController phoneCtrl = TextEditingController();

  bool loading = false;

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _afterSignIn(User user) async {
    final snap = await auth.getUserDoc(user.uid);
    if (snap == null || !(snap.data()?['pseudo'] is String)) {
      // ask for pseudo
      await _askForPseudo(user);
    }
    // go home
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    }
  }

  Future<bool?> _askForPseudo(User user) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Choisis un pseudo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            validator: (v) {
              if (v == null || v.trim().length < 3)
                return 'Au moins 3 caractères';
              return null;
            },
            decoration: const InputDecoration(labelText: 'Pseudo'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final pseudo = ctrl.text.trim();
                try {
                  await auth.setPseudoForExistingUser(
                    uid: user.uid,
                    pseudo: pseudo,
                  );
                  Navigator.pop(context, true);
                } catch (e) {
                  // pseudo exists or other error
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('S\'authentifier')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone (+223...)',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                setState(() => loading = true);
                try {
                  await auth.verifyPhone(
                    phone: phoneCtrl.text.trim(),
                    onCodeSent: (verificationId) {
                      setState(() => loading = false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtpPage(
                            verificationId: verificationId,
                            auth: auth,
                          ),
                        ),
                      );
                    },
                    onError: (e) {
                      setState(() => loading = false);
                      _showError(e.message ?? e.toString());
                    },
                  );
                } catch (e) {
                  setState(() => loading = false);
                  _showError(e.toString());
                }
              },
              child: loading
                  ? const CircularProgressIndicator.adaptive()
                  : const Text('Se connecter par téléphone'),
            ),
            const Divider(),
            ElevatedButton(
              onPressed: () async {
                setState(() => loading = true);
                try {
                  final cred = await auth.signInWithGoogle();
                  if (cred != null && cred.user != null)
                    await _afterSignIn(cred.user!);
                } catch (e) {
                  _showError(e.toString());
                } finally {
                  setState(() => loading = false);
                }
              },
              child: const Text('Se connecter avec Google'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() => loading = true);
                try {
                  final cred = await auth.signInWithApple();
                  if (cred != null && cred.user != null)
                    await _afterSignIn(cred.user!);
                } catch (e) {
                  _showError(e.toString());
                } finally {
                  setState(() => loading = false);
                }
              },
              child: const Text('Se connecter avec Apple'),
            ),
          ],
        ),
      ),
    );
  }
}
