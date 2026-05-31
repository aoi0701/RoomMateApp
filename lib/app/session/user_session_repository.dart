import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/profile/data/repositories/user_profile_repository.dart';
import 'user_session.dart';

/// Provides a single [sessionStream] that applies switchMap semantics over
/// Firebase auth state: each new [User?] emission cancels any in-flight role /
/// profile fetch for the previous user before starting fresh ones.
class UserSessionRepository {
  final AuthRepository _authRepository;
  final UserProfileRepository _profileRepository;

  late final Stream<UserSession?> sessionStream;

  UserSessionRepository({
    required AuthRepository authRepository,
    required UserProfileRepository profileRepository,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository {
    sessionStream = _buildStream();
  }

  Stream<UserSession?> _buildStream() {
    late StreamController<UserSession?> controller;
    StreamSubscription<User?>? authSub;
    // Typed as StreamSubscription<UserSession> to match the async* inner stream.
    StreamSubscription<UserSession>? innerSub;

    void cancelInner() {
      innerSub?.cancel();
      innerSub = null;
    }

    // Fetches role then profile for [user], yielding exactly one UserSession.
    // getUserRole runs first because it calls ensureUserDocument as a side-effect.
    Stream<UserSession> fetchSession(User user) async* {
      final role = await _authRepository.getUserRole(user.uid);
      final profile = await _profileRepository.getUserProfile(user.uid);
      yield UserSession(user: user, role: role, profile: profile);
    }

    controller = StreamController<UserSession?>(
      onListen: () {
        authSub = _authRepository.authStateChanges().listen(
          (user) {
            // Cancel previous fetch — switchMap semantics.
            cancelInner();
            if (user == null) {
              controller.add(null);
              return;
            }
            innerSub = fetchSession(user).listen(
              controller.add,
              onError: controller.addError,
            );
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        cancelInner();
        authSub?.cancel();
        authSub = null;
      },
    );

    return controller.stream;
  }
}
