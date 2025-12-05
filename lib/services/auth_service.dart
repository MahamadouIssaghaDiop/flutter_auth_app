import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // AUTH STATE
  // ---------------------------------------------------------------------------
  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // PHONE AUTH
  // ---------------------------------------------------------------------------
  Future<void> verifyPhone({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: timeout,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android auto-signin
        final userCred = await _auth.signInWithCredential(credential);
        await ensureUserExistsFromAuth(userCred.user!);
      },
      verificationFailed: onError,
      codeSent: (verificationId, _) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCred = await _auth.signInWithCredential(credential);
    await ensureUserExistsFromAuth(userCred.user!);
    return userCred;
  }

  // ---------------------------------------------------------------------------
  // GOOGLE AUTH
  // ---------------------------------------------------------------------------
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await _auth.signInWithCredential(credential);
    await ensureUserExistsFromAuth(userCred.user!);
    return userCred;
  }

  // ---------------------------------------------------------------------------
  // APPLE AUTH
  // ---------------------------------------------------------------------------
  Future<UserCredential?> signInWithApple() async {
    final appleCred = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCred = OAuthProvider('apple.com').credential(
      idToken: appleCred.identityToken,
      accessToken: appleCred.authorizationCode,
    );

    final userCred = await _auth.signInWithCredential(oauthCred);
    await ensureUserExistsFromAuth(userCred.user!);
    return userCred;
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE USER MANAGEMENT
  // ---------------------------------------------------------------------------

  /// Create Firestore user document if missing (CALLED AFTER EVERY LOGIN)
  Future<void> ensureUserExistsFromAuth(User user) async {
    final userRef = _db.collection('users').doc(user.uid);
    final snap = await userRef.get();

    if (!snap.exists) {
      await userRef.set({
        'uid': user.uid,
        'pseudo': '', // sera choisi plus tard
        'phone': user.phoneNumber,
        'email': user.email,
        'provider': user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Stream du profil utilisateur
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream() {
    final uid = currentUser!.uid;
    return _db.collection('users').doc(uid).snapshots();
  }

  /// Récupérer le document user une seule fois
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  // ---------------------------------------------------------------------------
  // PSEUDO UNIQUE
  // ---------------------------------------------------------------------------

  /// Création user avec pseudo unique
  Future<void> createUserWithPseudo({
    required String uid,
    required String pseudo,
    String? phoneNumber,
    String? displayName,
  }) async {
    final pseudoKey = pseudo.trim().toLowerCase();
    final usernamesRef = _db.collection('usernames').doc(pseudoKey);
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(usernamesRef);
      if (snap.exists) {
        throw Exception('Pseudo déjà utilisé');
      }

      tx.set(usernamesRef, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(userRef, {
        'uid': uid,
        'pseudo': pseudo,
        'phone': phoneNumber,
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Définir pseudo après login
  Future<void> setPseudoForExistingUser({
    required String uid,
    required String pseudo,
  }) async {
    final pseudoKey = pseudo.trim().toLowerCase();
    final usernamesRef = _db.collection('usernames').doc(pseudoKey);
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(usernamesRef);
      if (snap.exists) {
        throw Exception('Pseudo déjà utilisé');
      }

      tx.set(usernamesRef, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(userRef, {
        'pseudo': pseudo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
