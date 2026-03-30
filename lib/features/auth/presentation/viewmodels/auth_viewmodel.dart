import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  AuthViewModel({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  bool isLoading = false;
  String? errorMessage;

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

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String address,
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

      await _repository.resetPassword(email);
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

  Future<void> logout() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _repository.logout();
    } catch (e) {
      errorMessage = 'Đăng xuất thất bại: $e';
    } finally {
      isLoading = false;
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
}