import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/profile/data/models/user_model.dart';
import '../../features/profile/data/repositories/user_profile_repository.dart';
import 'user_session.dart';

/// Streams the current [UserSession?] with real-time Firestore listening.
///
/// When the Firestore user document changes (isBlocked, deleted, role),
/// this repository reacts immediately and signs the user out if needed —
/// WITHOUT any interaction from the widget layer.
///
/// AuthGate only routes; it never calls logout() from build().
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
    StreamSubscription<dynamic>? innerSub;

    void cancelInner() {
      innerSub?.cancel();
      innerSub = null;
    }

    controller = StreamController<UserSession?>(
      onListen: () {
        authSub = _authRepository.authStateChanges().listen(
          (user) {
            // Cancel any previous real-time listener (switchMap semantics).
            cancelInner();

            if (user == null) {
              controller.add(null);
              return;
            }

            // Ensure Firestore document exists for new users (Google sign-in, etc.),
            // then subscribe to real-time changes on that document.
            //
            // Guard: if logout() was called while ensureUserDocument was in flight
            // (e.g. getUserRole() in login() detected isBlocked), the authSub above
            // already ran cancelInner() before innerSub was assigned — creating a
            // zombie listener. Re-check currentUser before starting the stream.
            _authRepository.ensureUserDocument(user).then((_) {
              if (_authRepository.currentUser?.uid != user.uid) return;
              innerSub = _profileRepository
                  .getUserProfileStream(user.uid)
                  // Silently drop Firestore permission errors that occur
                  // during/after sign-out (rules deny reads for signed-out users).
                  .handleError((_) {})
                  .listen(
                (snap) {
                  if (!snap.exists) return;

                  final data = snap.data()!;

                  final isDeleted =
                      data['deleted'] == true || data['isDeleted'] == true;
                  final isBlocked = data['isBlocked'] == true;
                  final role = (data['role'] as String?) ?? 'user';
                  final isBanned = role == 'banned';

                  // ── Block / Delete / Ban detected ────────────────────────
                  // Stop the listener first so no further events arrive,
                  // then sign out fire-and-forget — Firebase Auth state
                  // change will propagate null to this stream automatically.
                  if (isDeleted || isBlocked || isBanned) {
                    cancelInner();
                    _authRepository.logout().ignore();
                    return;
                  }

                  // ── Normal session ────────────────────────────────────────
                  final profile = UserModel.fromDocument(snap);
                  if (!controller.isClosed) {
                    controller.add(
                      UserSession(user: user, role: role, profile: profile),
                    );
                  }
                },
              );
            }).catchError((_) {});
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

    return controller.stream.asBroadcastStream();
  }
}
