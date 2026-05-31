import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  User? get currentUser => _auth.currentUser;
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String gender,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;

    if (user != null) {
      await user.updateDisplayName(fullName.trim());

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': user.email,
        'phone': phone.trim(),
        'address': address.trim(),
        'gender': gender.trim(),
        'habits': const <String>[],
        'roommateCriteria': const <String>[],
        'profileCompleted': false,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  Future<String> getUserRole(String uid) async {
    final user = currentUser;
    if (user != null && user.uid == uid) {
      await ensureUserDocument(user);
    }

    try {
      final doc = await _users.doc(uid).get();
      return doc.data()?['role'] ?? 'user';
    } on FirebaseException {
      return 'user';
    }
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In cancelled by user');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw Exception('Không lấy được thông tin người dùng từ Google');
    }

    final docRef = _users.doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': user.uid,
        'fullName': user.displayName ?? '',
        'email': user.email ?? '',
        'avatarUrl': user.photoURL ?? '',
        'phone': '',
        'address': '',
        'gender': '',
        'habits': const <String>[],
        'roommateCriteria': const <String>[],
        'profileCompleted': false,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    // Role is not returned here; callers fetch it separately via getUserRole().
  }

  Future<void> resetPassword(String email) {
    final normalizedEmail = email.trim();
    return _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  Future<void> ensureUserDocument(User user) async {
    final docRef = _users.doc(user.uid);

    try {
      final doc = await docRef.get();
      if (doc.exists) return;
    } on FirebaseException {
      // Ignore Firestore read issues here so auth flows can continue.
    }

    try {
      await docRef.set({
        'uid': user.uid,
        'fullName': user.displayName ?? '',
        'email': user.email ?? '',
        'avatarUrl': user.photoURL ?? '',
        'phone': '',
        'address': '',
        'gender': '',
        'habits': const <String>[],
        'roommateCriteria': const <String>[],
        'profileCompleted': false,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Ignore Firestore write issues here so auth flows can continue.
    }
  }

  Future<void> logout() {
    return _auth.signOut();
  }
}
