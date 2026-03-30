import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../repositories/user_profile_repository.dart';

class UserProfileViewModel extends ChangeNotifier {
  final UserProfileRepository _repository;

  UserProfileViewModel({UserProfileRepository? repository})
      : _repository = repository ?? UserProfileRepository();

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfileStream(String uid) {
    return _repository.getUserProfileStream(uid);
  }
}