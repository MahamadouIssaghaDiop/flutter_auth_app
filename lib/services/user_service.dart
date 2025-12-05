import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream() {
    final uid = _auth.currentUser!.uid;
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> updatePseudo(String pseudo) async {
    final uid = _auth.currentUser!.uid;

    final pseudoKey = pseudo.toLowerCase().trim();
    final userRef = _db.collection('users').doc(uid);
    final usernameRef = _db.collection('usernames').doc(pseudoKey);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(usernameRef);
      if (snap.exists) {
        throw Exception("Pseudo déjà utilisé");
      }

      tx.set(usernameRef, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(userRef, {
        'pseudo': pseudo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> ensureProfile({
    required String pseudo,
    required String phone,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'pseudo': pseudo,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
