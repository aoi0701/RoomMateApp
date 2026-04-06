import 'package:flutter/material.dart';

import '../../data/models/roommate_profile_model.dart';
import '../../data/repositories/roommate_profile_repository.dart';

class RoommateProfileViewModel extends ChangeNotifier {
  final RoommateProfileRepository _repository;

  RoommateProfileViewModel({
    RoommateProfileRepository? repository,
  }) : _repository = repository ?? RoommateProfileRepository();

  bool isInviting = false;
  String? errorMessage;

  Stream<List<RoommateProfileModel>> get suggestedProfilesStream {
    return _repository.getSuggestedProfilesStream();
  }

  Future<bool> sendInvite({
    required String targetUserId,
    String message = '',
  }) async {
    try {
      isInviting = true;
      errorMessage = null;
      notifyListeners();

      await _repository.sendInvite(
        targetUserId: targetUserId,
        message: message,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      isInviting = false;
      notifyListeners();
    }
  }
}
