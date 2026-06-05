import 'package:rxdart/rxdart.dart';

import '../../features/profile/data/repositories/user_profile_repository.dart';

class UserProfile {
  final String name;
  final String? avatarUrl;

  const UserProfile({required this.name, this.avatarUrl});

  static const fallback = UserProfile(name: 'Người dùng');
}

// Cache tên và avatar user: mỗi userId chỉ mở 1 Firestore listener duy nhất,
// dùng chung cho tất cả widget cần dữ liệu của cùng 1 user (tránh mở N listener cho N widget).
// Tự hủy listener khi subscriber cuối cùng unsubscribe.
class UserNameCache {
  final UserProfileRepository _repository;
  final _cache = <String, Stream<UserProfile>>{};

  UserNameCache({required UserProfileRepository repository})
      : _repository = repository;

  Stream<UserProfile> profileStream(String userId) {
    return _cache[userId] ??= _repository
        .getUserProfileStream(userId)
        .map((doc) {
          if (!doc.exists) return UserProfile.fallback;
          final data = doc.data() ?? {};
          return UserProfile(
            name: data['fullName'] as String? ?? 'Người dùng',
            avatarUrl: data['avatarUrl'] as String?,
          );
        })
        .doOnError((_, _) => _cache.remove(userId))
        .shareValueSeeded(UserProfile.fallback);
  }
}
