import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final firebaseUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Profil"), centerTitle: true),
      body: StreamBuilder(
        stream: userService.userStream(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error / no data
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Profil introuvable"));
          }

          final data = snapshot.data!.data()!;

          final pseudo = (data['pseudo'] as String?)?.trim() ?? '';
          final phone =
              (data['phone'] as String?) ?? firebaseUser.phoneNumber ?? '—';

          final initial = pseudo.isNotEmpty ? pseudo[0].toUpperCase() : '👤';
          final provider = firebaseUser.providerData.isNotEmpty
              ? firebaseUser.providerData.first.providerId
              : 'inconnu';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 20),

              // ----------------------------------------------------------------
              // AVATAR
              // ----------------------------------------------------------------
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  pseudo.isNotEmpty ? pseudo : "Pseudo non défini",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),

              const SizedBox(height: 30),

              // ----------------------------------------------------------------
              // INFOS
              // ----------------------------------------------------------------
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text("Téléphone"),
                      subtitle: Text(phone),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text("Méthode de connexion"),
                      subtitle: Text(provider),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ----------------------------------------------------------------
              // ACTIONS
              // ----------------------------------------------------------------
              FilledButton.tonalIcon(
                onPressed: () => _showEditPseudo(context, userService, pseudo),
                icon: const Icon(Icons.edit),
                label: Text(
                  pseudo.isEmpty ? "Définir un pseudo" : "Modifier le pseudo",
                ),
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Se déconnecter"),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // EDIT PSEUDO
  // --------------------------------------------------------------------------
  void _showEditPseudo(
    BuildContext context,
    UserService service,
    String current,
  ) {
    final ctrl = TextEditingController(text: current);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Modifier le pseudo",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            TextField(
              controller: ctrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: "Pseudo",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            FilledButton(
              onPressed: () async {
                final newPseudo = ctrl.text.trim();
                if (newPseudo.isEmpty) return;

                await service.updatePseudo(newPseudo);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
