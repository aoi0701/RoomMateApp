import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'app/navigation/app_navigator.dart';
import 'core/services/user_name_cache.dart';
import 'app/session/user_session.dart';
import 'app/session/user_session_repository.dart';
import 'app/session/user_session_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/chat/data/repositories/chat_repository.dart';
import 'features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'features/expense/data/repositories/expense_repository.dart';
import 'features/expense/presentation/viewmodels/expense_viewmodel.dart';
import 'features/home/data/repositories/home_search_filter_repository.dart';
import 'features/home/data/repositories/roommate_profile_repository.dart';
import 'features/home/presentation/viewmodels/home_search_filter_viewmodel.dart';
import 'features/home/presentation/viewmodels/roommate_profile_viewmodel.dart';
import 'features/post/data/repositories/post_repository.dart';
import 'features/post/presentation/viewmodels/post_list_viewmodel.dart';
import 'features/post/presentation/viewmodels/post_viewmodel.dart';
import 'features/profile/data/repositories/user_profile_repository.dart';
import 'features/profile/presentation/viewmodels/user_profile_viewmodel.dart';
import 'features/profile/presentation/views/complete_profile_intro_screen.dart';
import 'features/room_group/data/repositories/room_group_repository.dart';
import 'features/room_group/presentation/viewmodels/room_group_viewmodel.dart';
import 'features/roommate/data/repositories/roommate_request_repository.dart';
import 'features/roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import 'features/auth/presentation/views/login_screen.dart';
import 'features/home/presentation/views/user_home_screen.dart';
import 'firebase_options.dart';

const _dbUrl =
    'https://roommateapp-fbb4f-default-rtdb.asia-southeast1.firebasedatabase.app';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _dbUrl,
  );
  final googleSignIn = GoogleSignIn();
  final navigationService = NavigationService();

  runApp(MyApp(
    auth: auth,
    firestore: firestore,
    database: database,
    googleSignIn: googleSignIn,
    navigationService: navigationService,
  ));
}

class MyApp extends StatelessWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseDatabase database;
  final GoogleSignIn googleSignIn;
  final NavigationService navigationService;

  const MyApp({
    super.key,
    required this.auth,
    required this.firestore,
    required this.database,
    required this.googleSignIn,
    required this.navigationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<NavigationService>.value(value: navigationService),
        Provider<AuthRepository>(
          create: (_) => AuthRepository(
            auth: auth,
            firestore: firestore,
            googleSignIn: googleSignIn,
          ),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            repository: context.read<AuthRepository>(),
          ),
        ),
        Provider<PostRepository>(
          create: (_) => PostRepository(auth: auth, firestore: firestore),
        ),
        Provider<HomeSearchFilterRepository>(
          create: (_) => HomeSearchFilterRepository(
            auth: auth,
            firestore: firestore,
          ),
        ),
        Provider<RoommateProfileRepository>(
          create: (_) => RoommateProfileRepository(
            auth: auth,
            firestore: firestore,
          ),
        ),
        Provider<UserProfileRepository>(
          create: (_) => UserProfileRepository(firestore: firestore),
        ),
        Provider<UserNameCache>(
          create: (context) => UserNameCache(
            repository: context.read<UserProfileRepository>(),
          ),
        ),
        Provider<UserSessionRepository>(
          create: (context) => UserSessionRepository(
            authRepository: context.read<AuthRepository>(),
            profileRepository: context.read<UserProfileRepository>(),
          ),
        ),
        Provider<RoommateRequestRepository>(
          create: (_) => RoommateRequestRepository(
            auth: auth,
            firestore: firestore,
          ),
        ),
        Provider<RoomGroupRepository>(
          create: (_) => RoomGroupRepository(auth: auth, firestore: firestore),
        ),
        Provider<ExpenseRepository>(
          create: (_) => ExpenseRepository(auth: auth, firestore: firestore),
        ),
        Provider<ChatRepository>(
          create: (_) => ChatRepository(auth: auth, db: database),
        ),
        ChangeNotifierProvider<ChatViewModel>(
          create: (context) => ChatViewModel(
            repository: context.read<ChatRepository>(),
          ),
        ),
        ChangeNotifierProvider<ExpenseViewModel>(
          create: (context) => ExpenseViewModel(
            repository: context.read<ExpenseRepository>(),
          ),
        ),
        ChangeNotifierProvider<RoommateRequestViewModel>(
          create: (context) => RoommateRequestViewModel(
            repository: context.read<RoommateRequestRepository>(),
            roomGroupRepository: context.read<RoomGroupRepository>(),
          ),
        ),
        ChangeNotifierProvider<RoomGroupViewModel>(
          create: (context) => RoomGroupViewModel(
            repository: context.read<RoomGroupRepository>(),
          ),
        ),
        ChangeNotifierProvider<PostViewModel>(
          create: (context) => PostViewModel(
            repository: context.read<PostRepository>(),
          ),
        ),
        ChangeNotifierProvider<PostListViewModel>(
          create: (context) => PostListViewModel(
            repository: context.read<PostRepository>(),
          ),
        ),
        ChangeNotifierProvider<HomeSearchFilterViewModel>(
          create: (context) => HomeSearchFilterViewModel(
            repository: context.read<HomeSearchFilterRepository>(),
          ),
        ),
        ChangeNotifierProvider<RoommateProfileViewModel>(
          create: (context) => RoommateProfileViewModel(
            repository: context.read<RoommateProfileRepository>(),
          ),
        ),
        ChangeNotifierProvider<UserProfileViewModel>(
          create: (context) => UserProfileViewModel(
            repository: context.read<UserProfileRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'RoomMate',
        theme: AppTheme.light,
        builder: (context, child) {
          if (child == null) {
            return const SizedBox.shrink();
          }

          final user = context.watch<AuthViewModel>().user;
          if (user == null) {
            return child;
          }

          return UserSessionScope(
            key: ValueKey(user.uid),
            child: child,
          );
        },
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Tracks whether we already requested a logout for the current error state
  // so we don't fire it on every rebuild.
  bool _logoutScheduled = false;

  void _scheduleLogout() {
    if (_logoutScheduled) return;
    _logoutScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logoutScheduled = false;
      if (!mounted) return;
      final vm = context.read<AuthViewModel>();
      if (!vm.isLoggingOut) vm.logout();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return StreamBuilder<UserSession?>(
      stream: context.read<UserSessionRepository>().sessionStream,
      builder: (context, snapshot) {
        // ── Loading ──────────────────────────────────────────────────────────
        if (authVm.isLoggingOut ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ── Stream error ─────────────────────────────────────────────────────
        // Only force sign-out for persistent errors while Firebase Auth still
        // has a user. Uses _scheduleLogout() to avoid calling logout() from
        // inside build(), which causes lifecycle assertion failures.
        if (snapshot.hasError && authVm.user != null) {
          _scheduleLogout();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ── No session → login ───────────────────────────────────────────────
        // UserSessionRepository already called logout() for banned/blocked/deleted
        // users, so null session is the safe steady state → show LoginScreen.
        final session = snapshot.data;
        if (session == null) {
          _logoutScheduled = false; // Reset for next login
          return const LoginScreen();
        }

        // ── Safety net: if session somehow carries a restricted role ─────────
        // UserSessionRepository should have already signed the user out,
        // but as a defence-in-depth guard we return LoginScreen without
        // calling logout() again (it's already in flight).
        if (session.role == 'banned' ||
            session.role == 'deleted' ||
            session.role == 'blocked') {
          return const LoginScreen();
        }

        // ── Route by profile completeness ────────────────────────────────────
        final profile = session.profile;
        if (profile != null && !profile.profileCompleted) {
          return const CompleteProfileIntroScreen();
        }

        return const UserHomeScreen();
      },
    );
  }
}
