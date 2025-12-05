import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'profile_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Accueil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: userService.userStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Bienvenue 👋"));
          }

          final data = snapshot.data!.data()!;
          final pseudo = (data['pseudo'] as String?)?.trim();

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pseudo != null && pseudo.isNotEmpty
                      ? "Bienvenue $pseudo 👋"
                      : "Bienvenue 👋",
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                FilledButton(onPressed: () {}, child: const Text("Commencer")),
              ],
            ),
          );
        },
      ),
    );
  }
}
