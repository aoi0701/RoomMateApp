import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  late final StreamSubscription<User?> _authSubscription;
  bool _isLoggingOut = false;

  AuthViewModel({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _authSubscription = _repository.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  bool isLoading = false;
  String? errorMessage;
  bool get isLoggingOut => _isLoggingOut;

  User? get user => _repository.currentUser;

  Future<String?> login(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final credential = await _repository.login(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        errorMessage = 'Không tìm thấy thông tin người dùng';
        return null;
      }

      final role = await _repository.getUserRole(user.uid);
      return role;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapFirebaseAuthError(e);
      return null;
    } catch (e) {
      errorMessage = 'Đã có lỗi xảy ra: $e';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final role = await _repository.signInWithGoogle();
      return role;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled' || e.code == 'network_error') {
        errorMessage = null;
      } else {
        errorMessage = e.message ?? 'Đăng nhập Google thất bại';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapFirebaseAuthError(e);
      return null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelled')) {
        errorMessage = null;
      } else {
        errorMessage = 'Đăng nhập Google thất bại: $e';
      }
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String gender,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        address: address,
        gender: gender,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mapFirebaseAuthError(e);
      return false;
    } catch (e) {
      errorMessage = 'Đã có lỗi xảy ra: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _repository.resetPassword(email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = '[${e.code}] ${e.message ?? _mapFirebaseAuthError(e)}';
      return false;
    } catch (e) {
      errorMessage = 'Đã có lỗi xảy ra: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get hasError => errorMessage != null;

  Future<void> logout() async {
    if (_isLoggingOut) return;

    try {
      isLoading = true;
      _isLoggingOut = true;
      errorMessage = null;
      notifyListeners();

      await WidgetsBinding.instance.endOfFrame;
      await _repository.logout();
    } catch (e) {
      errorMessage = 'Đăng xuất thất bại: $e';
    } finally {
      isLoading = false;
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều lần. Vui lòng thử lại sau';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'network-request-failed':
        return 'Lỗi mạng, vui lòng thử lại';
      default:
        return e.message ?? 'Đã xảy ra lỗi xác thực';
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
