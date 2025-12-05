import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _pseudoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool loading = false;

  final userService = UserService();

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final pseudo = _pseudoCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (pseudo.length < 3) {
      _showError("Le pseudo doit contenir au moins 3 caractères");
      return;
    }

    if (phone.length < 6) {
      _showError("Numéro de téléphone invalide");
      return;
    }

    setState(() => loading = true);

    try {
      await userService.ensureProfile(pseudo: pseudo, phone: phone);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Compléter le profil"),
        automaticallyImplyLeading: false, // 🔒 bloquant
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Text(
              "Dernière étape 👇",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _pseudoCtrl,
              decoration: const InputDecoration(
                labelText: "Pseudo *",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Téléphone *",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : _save,
                child: loading
                    ? const CircularProgressIndicator.adaptive()
                    : const Text("Continuer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
