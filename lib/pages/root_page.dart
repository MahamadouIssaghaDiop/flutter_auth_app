import 'package:auth_app/pages/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_page.dart';
import 'complete_profile_page.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) {
          return const AuthPage();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const CompleteProfilePage();
            }

            final data = userSnap.data!.data()!;
            final pseudo = (data['pseudo'] as String?)?.trim();
            final phone = (data['phone'] as String?)?.trim();

            final pseudoMissing = pseudo == null || pseudo.isEmpty;
            final phoneMissing = phone == null || phone.isEmpty;

            if (pseudoMissing || phoneMissing) {
              return const CompleteProfilePage();
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
