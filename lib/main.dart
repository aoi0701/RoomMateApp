import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/auth/presentation/views/login_screen.dart';
import 'features/home/presentation/views/user_home_screen.dart';
import 'features/home/data/repositories/home_search_filter_repository.dart';
import 'features/home/data/repositories/roommate_profile_repository.dart';
import 'features/home/presentation/viewmodels/home_search_filter_viewmodel.dart';
import 'features/home/presentation/viewmodels/roommate_profile_viewmodel.dart';
import 'features/post/data/repositories/post_repository.dart';
import 'features/profile/data/models/user_model.dart';
import 'features/profile/data/repositories/user_profile_repository.dart';
import 'features/post/presentation/viewmodels/post_list_viewmodel.dart';
import 'features/post/presentation/viewmodels/post_viewmodel.dart';
import 'features/profile/presentation/viewmodels/user_profile_viewmodel.dart';
import 'features/profile/presentation/views/complete_profile_intro_screen.dart';
import 'features/roommate/data/repositories/roommate_request_repository.dart';
import 'features/roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import 'features/room_group/data/repositories/room_group_repository.dart';
import 'features/room_group/presentation/viewmodels/room_group_viewmodel.dart';
import 'features/expense/data/repositories/expense_repository.dart';
import 'features/expense/presentation/viewmodels/expense_viewmodel.dart';
import 'features/chat/data/repositories/chat_repository.dart';
import 'features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            repository: context.read<AuthRepository>(),
          ),
        ),
        Provider<PostRepository>(
          create: (_) => PostRepository(),
        ),
        Provider<HomeSearchFilterRepository>(
          create: (_) => HomeSearchFilterRepository(),
        ),
        Provider<RoommateProfileRepository>(
          create: (_) => RoommateProfileRepository(),
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
        Provider<UserProfileRepository>(
          create: (_) => UserProfileRepository(),
        ),
        ChangeNotifierProvider<UserProfileViewModel>(
          create: (context) => UserProfileViewModel(
            repository: context.read<UserProfileRepository>(),
          ),
        ),
        Provider<RoommateRequestRepository>(
          create: (_) => RoommateRequestRepository(),
        ),
        Provider<RoomGroupRepository>(
          create: (_) => RoomGroupRepository(),
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
        Provider<ExpenseRepository>(
          create: (_) => ExpenseRepository(),
        ),
        ChangeNotifierProvider<ExpenseViewModel>(
          create: (context) => ExpenseViewModel(
            repository: context.read<ExpenseRepository>(),
          ),
        ),
        Provider<ChatRepository>(
          create: (_) => ChatRepository(),
        ),
        ChangeNotifierProvider<ChatViewModel>(
          create: (context) => ChatViewModel(
            repository: context.read<ChatRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RoomMate',
        theme: AppTheme.light,
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
  String? _cachedRole;
  String? _cachedRoleUserId;

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          _cachedRole = null;
          _cachedRoleUserId = null;
          return const LoginScreen();
        }

        if (_cachedRoleUserId != user.uid) {
          _cachedRole = null;
          _cachedRoleUserId = user.uid;
        }

        if (_cachedRole != null) {
          if (_cachedRole == 'banned') {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await authRepository.logout();
            });
            return const LoginScreen();
          }

          return const UserHomeScreen();
        }

        return FutureBuilder<String>(
          future: authRepository.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final role = roleSnapshot.data ?? 'user';
            _cachedRole = role;
            _cachedRoleUserId = user.uid;

            if (role == 'banned') {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await authRepository.logout();
              });
              return const LoginScreen();
            }

            return FutureBuilder<UserModel?>(
              future: context.read<UserProfileViewModel>().getUserProfile(user.uid),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final profile = profileSnapshot.data;
                if (profile != null && !profile.profileCompleted) {
                  return const CompleteProfileIntroScreen();
                }

                return const UserHomeScreen();
              },
            );
          },
        );
      },
    );
  }
}
