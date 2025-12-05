import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTest {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> testWrite() async {
    await _db.collection('test').doc('hello').set({
      'message': 'Firestore connecté 🎉',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> testReadStream() {
    return _db.collection('test').snapshots();
  }
}
