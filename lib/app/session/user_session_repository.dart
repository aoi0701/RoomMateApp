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
    // Guards against a race where Firebase fires a spurious authStateChanges
    // event (e.g. a background token-refresh completes) between the moment we
    // call logout() and the moment Firebase confirms sign-out.  Without this
    // flag the listener would restart, detect isBlocked again, call logout()
    // again — creating an infinite sign-out / sign-in loop.
    bool kickedOut = false;

    void cancelInner() {
      innerSub?.cancel();
      innerSub = null;
    }

    controller = StreamController<UserSession?>(
      onListen: () {
        authSub = _authRepository.authStateChanges().listen(
          (user) {
            cancelInner();

            if (user == null) {
              kickedOut = false; // Reset so a fresh login works normally.
              controller.add(null);
              return;
            }

            // A spurious re-sign-in arrived while we are waiting for Firebase
            // to confirm the sign-out we already requested.  Force another
            // logout and bail — do NOT restart the Firestore listener.
            if (kickedOut) {
              _authRepository.logout().ignore();
              return;
            }

            _authRepository.ensureUserDocument(user).then((_) {
              if (_authRepository.currentUser?.uid != user.uid) return;
              if (kickedOut) return;

              innerSub = _profileRepository
                  .getUserProfileStream(user.uid)
                  .handleError((error) {
                    // PERMISSION_DENIED means the user was blocked/deleted and
                    // security rules revoked access — treat as a kick-out.
                    kickedOut = true;
                    cancelInner();
                    if (!controller.isClosed) controller.add(null);
                    _authRepository.logout().ignore();
                  })
                  .listen(
                (snap) {
                  if (!snap.exists) {
                    // Document was hard-deleted (e.g. from Firebase console).
                    kickedOut = true;
                    cancelInner();
                    if (!controller.isClosed) controller.add(null);
                    _authRepository.logout().ignore();
                    return;
                  }

                  final data = snap.data()!;

                  final isDeleted =
                      data['deleted'] == true || data['isDeleted'] == true;
                  final isBlocked = data['isBlocked'] == true;
                  final role = (data['role'] as String?) ?? 'user';
                  final isBanned = role == 'banned';

                  // ── Block / Delete / Ban detected ────────────────────────
                  // 1. Set kickedOut flag first so any spurious auth event
                  //    that fires during sign-out does not restart the listener.
                  // 2. Emit null immediately so AuthGate shows LoginScreen
                  //    right away without waiting for Firebase to confirm
                  //    sign-out (avoids PERMISSION_DENIED flash on home screen).
                  // 3. Fire logout() in the background.
                  if (isDeleted || isBlocked || isBanned) {
                    kickedOut = true;
                    cancelInner();
                    if (!controller.isClosed) controller.add(null);
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
        kickedOut = false;
      },
    );

    return controller.stream.asBroadcastStream();
  }
}
