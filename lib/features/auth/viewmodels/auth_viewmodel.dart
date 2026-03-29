import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  String? error;

  User? get user => _auth.currentUser;

  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      error = null;
      return true;
    } on FirebaseAuthException catch (e) {
      error = e.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

Future<bool> register(String fullName, String email, String password) async {
  try {
    isLoading = true;
    notifyListeners();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'fullName': fullName,
        'email': user.email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    error = null;
    return true;
  } on FirebaseAuthException catch (e) {
    error = e.message;
    return false;
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}