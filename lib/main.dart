import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_colors.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/auth/presentation/views/login_screen.dart';
import 'features/admin/presentation/views/admin_home_screen.dart';
import 'features/home/presentation/views/user_home_screen.dart';
import 'features/home/data/repositories/home_search_filter_repository.dart';
import 'features/home/data/repositories/roommate_profile_repository.dart';
import 'features/home/presentation/viewmodels/home_search_filter_viewmodel.dart';
import 'features/home/presentation/viewmodels/roommate_profile_viewmodel.dart';
import 'features/post/data/repositories/post_repository.dart';
import 'features/profile/data/repositories/user_profile_repository.dart';
import 'features/post/presentation/viewmodels/post_list_viewmodel.dart';
import 'features/post/presentation/viewmodels/post_viewmodel.dart';
import 'features/profile/presentation/viewmodels/user_profile_viewmodel.dart';
import 'features/roommate/data/repositories/roommate_request_repository.dart';
import 'features/roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
      ChangeNotifierProvider<RoommateRequestViewModel>(
        create: (context) => RoommateRequestViewModel(
          repository: context.read<RoommateRequestRepository>(),
        ),
      ),
    ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Find Roommate',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
          return const LoginScreen();
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
            if (role == 'admin') {
              return const AdminHomeScreen();
            }

            return const UserHomeScreen();
          },
        );
      },
    );
  }
}
