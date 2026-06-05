import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/user_profile_repository.dart';

// ViewModel hồ sơ user: cache in-memory 5 phút để giảm Firestore reads, tự invalidate khi cập nhật
class UserProfileViewModel extends ChangeNotifier {
  final UserProfileRepository _repository;
  final Map<String, UserModel> _profileCache = <String, UserModel>{};
  final Map<String, DateTime> _profileCacheTime = <String, DateTime>{};
  bool isSavingHabits = false;
  bool isSubmittingProfile = false;
  String? errorMessage;

  UserProfileViewModel({required UserProfileRepository repository})
      : _repository = repository;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) {
    return _repository.getUserProfileStream(uid);
  }

  Stream<bool> hasUserPostsStream(String uid) {
    return _repository.hasUserPostsStream(uid);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final cachedProfile = _profileCache[uid];
    final cachedTime = _profileCacheTime[uid];
    final isFresh = cachedTime != null &&
        DateTime.now().difference(cachedTime).inMinutes < 5;
    if (cachedProfile != null && isFresh) return cachedProfile;

    final profile = await _repository.getUserProfile(uid);
    if (profile != null) {
      _profileCache[uid] = profile;
      _profileCacheTime[uid] = DateTime.now();
    }
    return profile;
  }

  Future<bool> isProfileComplete(String uid) {
    return _repository.isProfileComplete(uid);
  }

  Future<bool> updateHabits({
    required String uid,
    required List<String> habits,
  }) async {
    try {
      isSavingHabits = true;
      errorMessage = null;
      notifyListeners();

      await _repository.updateHabits(uid: uid, habits: habits);
      _profileCache.remove(uid);
      return true;
    } catch (e) {
      errorMessage = 'Không thể cập nhật thói quen: $e';
      return false;
    } finally {
      isSavingHabits = false;
      notifyListeners();
    }
  }

  bool isUpdatingInfo = false;

  Future<bool> updateBasicInfo({
    required String uid,
    required String fullName,
    required String phone,
    required String address,
    required String gender,
  }) async {
    try {
      isUpdatingInfo = true;
      errorMessage = null;
      notifyListeners();
      await _repository.updateBasicInfo(
        uid: uid,
        fullName: fullName,
        phone: phone,
        address: address,
        gender: gender,
      );
      _profileCache.remove(uid);
      return true;
    } catch (e) {
      errorMessage = 'Không thể cập nhật thông tin: $e';
      return false;
    } finally {
      isUpdatingInfo = false;
      notifyListeners();
    }
  }

  bool isDeletingAccount = false;

  Future<bool> deleteAccount(String uid) async {
    try {
      isDeletingAccount = true;
      errorMessage = null;
      notifyListeners();

      await _repository.softDeleteAccount(uid);
      return true;
    } catch (e) {
      errorMessage = 'Không thể xóa tài khoản: $e';
      return false;
    } finally {
      isDeletingAccount = false;
      notifyListeners();
    }
  }

  Future<bool> completeProfile({
    required String uid,
    required String phone,
    required String address,
    required String gender,
    required List<String> habits,
  }) async {
    try {
      isSubmittingProfile = true;
      errorMessage = null;
      notifyListeners();

      await _repository.completeProfile(
        uid: uid,
        phone: phone,
        address: address,
        gender: gender,
        habits: habits,
      );
      _profileCache.remove(uid);
      return true;
    } catch (e) {
      errorMessage = 'Không thể hoàn thiện hồ sơ: $e';
      return false;
    } finally {
      isSubmittingProfile = false;
      notifyListeners();
    }
  }
}
