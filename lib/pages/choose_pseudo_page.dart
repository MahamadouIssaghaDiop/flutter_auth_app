import 'package:flutter/material.dart';
import '../services/user_service.dart';

class ChoosePseudoPage extends StatefulWidget {
  const ChoosePseudoPage({super.key});

  @override
  State<ChoosePseudoPage> createState() => _ChoosePseudoPageState();
}

class _ChoosePseudoPageState extends State<ChoosePseudoPage> {
  final _ctrl = TextEditingController();
  final _service = UserService();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pseudo = _ctrl.text.trim();

    if (pseudo.length < 3) {
      setState(() => error = "Minimum 3 caractères");
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await _service.updatePseudo(pseudo);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choisir un pseudo"),
        automaticallyImplyLeading: false, // 🔒
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            Text(
              "Ce pseudo sera visible par les autres utilisateurs.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: "Pseudo",
                border: OutlineInputBorder(),
              ),
            ),

            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 20),

            FilledButton(
              onPressed: loading ? null : _save,
              child: loading
                  ? const CircularProgressIndicator.adaptive()
                  : const Text("Continuer"),
            ),
          ],
        ),
      ),
    );
  }
}
