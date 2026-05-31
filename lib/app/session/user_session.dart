import 'package:firebase_auth/firebase_auth.dart';

import '../../features/profile/data/models/user_model.dart';

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
