import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/presentation/viewmodels/chat_viewmodel.dart';
import '../../features/expense/data/repositories/expense_repository.dart';
import '../../features/expense/presentation/viewmodels/expense_viewmodel.dart';
import '../../features/home/data/repositories/home_search_filter_repository.dart';
import '../../features/home/data/repositories/roommate_profile_repository.dart';
import '../../features/home/presentation/viewmodels/home_search_filter_viewmodel.dart';
import '../../features/home/presentation/viewmodels/roommate_profile_viewmodel.dart';
import '../../features/post/data/repositories/post_repository.dart';
import '../../features/post/presentation/viewmodels/post_list_viewmodel.dart';
import '../../features/post/presentation/viewmodels/post_viewmodel.dart';
import '../../features/profile/data/repositories/user_profile_repository.dart';
import '../../features/profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../features/room_group/data/repositories/room_group_repository.dart';
import '../../features/room_group/presentation/viewmodels/room_group_viewmodel.dart';
import '../../features/roommate/data/repositories/roommate_request_repository.dart';
import '../../features/roommate/presentation/viewmodels/roommate_request_viewmodel.dart';

// Tạo lại các ViewModel phụ thuộc session sau khi user đăng nhập thành công,
// đảm bảo chúng được reset sạch khi user thay đổi (key = uid)
class UserSessionScope extends StatelessWidget {
  final Widget child;

  const UserSessionScope({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        ChangeNotifierProvider<UserProfileViewModel>(
          create: (context) => UserProfileViewModel(
            repository: context.read<UserProfileRepository>(),
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
        ChangeNotifierProvider<ExpenseViewModel>(
          create: (context) => ExpenseViewModel(
            repository: context.read<ExpenseRepository>(),
          ),
        ),
        ChangeNotifierProvider<ChatViewModel>(
          create: (context) => ChatViewModel(
            repository: context.read<ChatRepository>(),
          ),
        ),
      ],
      child: child,
    );
  }
}
