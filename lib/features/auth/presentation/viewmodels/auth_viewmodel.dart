import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/viewmodels/view_model_base.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ViewModelBase {
  final AuthRepository _repository;
  late final StreamSubscription<User?> _authSubscription;
  bool _isLoggingOut = false;

  AuthViewModel({required AuthRepository repository})
      : _repository = repository {
    _authSubscription = _repository.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  bool get isLoggingOut => _isLoggingOut;
  bool get hasError => errorMessage != null;

  User? get user => _repository.currentUser;

  Future<String?> login(String email, String password) async {
    try {
      beginLoad();

      final credential = await _repository.login(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        setError('Không tìm thấy thông tin người dùng');
        return null;
      }

      final role = await _repository.getUserRole(user.uid);
      if (role == 'deleted') {
        await _repository.logout();
        setError('Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.');
        return null;
      }
      if (role == 'blocked') {
        await _repository.logout();
        setError('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.');
        return null;
      }
      return role;
    } on FirebaseAuthException catch (e) {
      setError(_mapFirebaseAuthError(e));
      return null;
    } catch (e) {
      setError('Đã có lỗi xảy ra: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      beginLoad();

      await _repository.signInWithGoogle();

      final user = _repository.currentUser;
      if (user == null) return;

      final role = await _repository.getUserRole(user.uid);
      if (role == 'deleted') {
        await _repository.logout();
        setError('Tài khoản đã bị vô hiệu hóa. Vui lòng liên hệ hỗ trợ.');
      } else if (role == 'blocked') {
        await _repository.logout();
        setError('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.');
      } else if (role == 'banned') {
        await _repository.logout();
        setError('Tài khoản của bạn đã bị khóa.');
      }
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled' || e.code == 'network_error') {
        setError(null);
      } else {
        setError(e.message ?? 'Đăng nhập Google thất bại');
      }
    } on FirebaseAuthException catch (e) {
      setError(_mapFirebaseAuthError(e));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelled')) {
        setError(null);
      } else {
        setError('Đăng nhập Google thất bại: $e');
      }
    } finally {
      setLoading(false);
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
      beginLoad();

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
      setError(_mapFirebaseAuthError(e));
      return false;
    } catch (e) {
      setError('Đã có lỗi xảy ra: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      beginLoad();

      await _repository.resetPassword(email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      setError('[${e.code}] ${e.message ?? _mapFirebaseAuthError(e)}');
      return false;
    } catch (e) {
      setError('Đã có lỗi xảy ra: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;

    try {
      _isLoggingOut = true;
      beginLoad();

      await WidgetsBinding.instance.endOfFrame;
      await _repository.logout();
    } catch (e) {
      setError('Đăng xuất thất bại: $e');
    } finally {
      _isLoggingOut = false;
      setLoading(false);
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
