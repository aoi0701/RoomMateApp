import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

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
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'user';
  }

  Future<String> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
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

    final docRef = _firestore.collection('users').doc(user.uid);
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

    final role = doc.exists ? (doc.data()?['role'] ?? 'user') : 'user';
    return role as String;
  }

  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() {
    return _auth.signOut();
  }
}
