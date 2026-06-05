import 'package:firebase_auth/firebase_auth.dart';

import '../../features/profile/data/models/user_model.dart';

// Model phiên làm việc của user: gộp Firebase Auth user, vai trò và hồ sơ Firestore
class UserSession {
  final User user;
  final String role;
  final UserModel? profile;

  const UserSession({
    required this.user,
    required this.role,
    this.profile,
  });
}
