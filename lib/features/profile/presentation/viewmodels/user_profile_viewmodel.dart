import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/user_profile_repository.dart';

class UserProfileViewModel extends ChangeNotifier {
  final UserProfileRepository _repository;
  final Map<String, UserModel> _profileCache = <String, UserModel>{};

  UserProfileViewModel({UserProfileRepository? repository})
      : _repository = repository ?? UserProfileRepository();

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) {
    return _repository.getUserProfileStream(uid);
  }

  Stream<bool> hasUserPostsStream(String uid) {
    return _repository.hasUserPostsStream(uid);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final cachedProfile = _profileCache[uid];
    if (cachedProfile != null) return cachedProfile;

    final profile = await _repository.getUserProfile(uid);
    if (profile != null) {
      _profileCache[uid] = profile;
    }
    return profile;
  }

  bool isSavingHabits = false;
  String? errorMessage;

  Future<bool> updateHabits({
    required String uid,
    required List<String> habits,
  }) async {
    try {
      isSavingHabits = true;
      errorMessage = null;
      notifyListeners();

      await _repository.updateHabits(uid: uid, habits: habits);
      return true;
    } catch (e) {
      errorMessage = 'Không thể cập nhật thói quen: $e';
      return false;
    } finally {
      isSavingHabits = false;
      notifyListeners();
    }
  }
}
