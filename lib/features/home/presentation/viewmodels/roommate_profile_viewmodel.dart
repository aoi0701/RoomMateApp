import 'package:flutter/material.dart';

import '../../data/models/roommate_profile_model.dart';
import '../../data/repositories/roommate_profile_repository.dart';

class RoommateProfileViewModel extends ChangeNotifier {
  final RoommateProfileRepository _repository;

  RoommateProfileViewModel({
    required RoommateProfileRepository repository,
  }) : _repository = repository;

  bool isInviting = false;
  String? errorMessage;

  final Set<String> _invitedUserIds = {};

  bool isInvited(String userId) => _invitedUserIds.contains(userId);

  Stream<List<RoommateProfileModel>> get suggestedProfilesStream =>
      _repository.getSuggestedProfilesStream();

  Future<bool> sendInvite({
    required String targetUserId,
    required String targetName,
    required String targetAvatar,
    String message = '',
  }) async {
    try {
      isInviting = true;
      errorMessage = null;
      notifyListeners();

      await _repository.sendInvite(
        targetUserId: targetUserId,
        targetName: targetName,
        targetAvatar: targetAvatar,
        message: message,
      );

      _invitedUserIds.add(targetUserId);
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
