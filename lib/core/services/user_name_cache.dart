import 'package:rxdart/rxdart.dart';

import '../../features/profile/data/repositories/user_profile_repository.dart';

class UserProfile {
  final String name;
  final String? avatarUrl;

  const UserProfile({required this.name, this.avatarUrl});

  static const fallback = UserProfile(name: 'Người dùng');
}

/// Maintains one shared Firestore listener per userId.
///
/// [profileStream] returns the same [Stream] instance for every caller with
/// the same [userId]. [shareValueSeeded] provides ref-counting: the underlying
/// listener opens when the first subscriber attaches and is cancelled when the
/// last one detaches, so a screen with 10 debt rows for 3 distinct users
/// opens exactly 3 listeners — not 10.
///
/// On stream error the cached entry is removed so the next subscriber gets a
/// fresh listener instead of a closed stream.
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
