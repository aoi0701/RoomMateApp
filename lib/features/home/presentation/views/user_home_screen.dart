import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/room_search_filter_model.dart';
import '../../data/models/roommate_profile_model.dart';
import '../viewmodels/home_search_filter_viewmodel.dart';
import '../viewmodels/roommate_profile_viewmodel.dart';
import '../widgets/home_header_widget.dart';
import '../widgets/invite_sheet_widget.dart';
import '../widgets/posts_feed_section_widget.dart';
import '../widgets/suggested_profiles_section_widget.dart';
import 'room_search_filter_screen.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../chat/data/models/chat_conversation_model.dart';
import '../../../chat/presentation/viewmodels/chat_viewmodel.dart';
import '../../../chat/presentation/views/chat_list_screen.dart';
import '../../../roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import '../../../roommate/presentation/views/roommate_request_tab_screen.dart';
import '../../../post/data/models/post_model.dart';
import '../../../post/presentation/viewmodels/post_list_viewmodel.dart';
import '../../../post/presentation/views/post_detail_screen.dart';
import '../../../post/presentation/views/post_form_screen.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../../profile/presentation/views/complete_profile_flow_screen.dart';
import '../../../profile/presentation/views/user_profile_screen.dart';
import '../../../room_group/presentation/views/room_group_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  Stream<List<ChatConversationModel>>? _unreadConversationsStream;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeSearchFilterViewModel>().loadSavedFilter().then((_) {
        if (!mounted) return;
        context.read<PostListViewModel>().applyFilter(
          context.read<HomeSearchFilterViewModel>().currentFilter,
        );
      });
      context.read<RoommateRequestViewModel>().ensureReceivedRequestsListening();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      context.read<PostListViewModel>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Stream<List<ChatConversationModel>> _getUnreadConversationsStream() {
    return _unreadConversationsStream ??=
        context.read<ChatViewModel>().getConversationsStream();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  Future<void> _openFilterScreen(RoomSearchFilterModel filter) async {
    final result = await Navigator.push<RoomSearchFilterModel>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomSearchFilterScreen(initialFilter: filter),
      ),
    );
    if (result != null && mounted) {
      context.read<HomeSearchFilterViewModel>().updateFilterLocally(result);
      context.read<PostListViewModel>().applyFilter(result);
    }
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostFormScreen()),
    );
  }

  void _openPostDetail(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          post: post,
          currentUserId: context.read<AuthViewModel>().user?.uid,
        ),
      ),
    );
  }

  void _openSuggestedProfile(RoommateProfileModel profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: profile.userId,
          matchPercentage: profile.matchPercentage,
          showInviteAction: true,
        ),
      ),
    );
  }

  void _showInviteBottomSheet(RoommateProfileModel profile) {
    final vm = context.read<RoommateProfileViewModel>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: InviteSheetWidget(profile: profile),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildHomeFeedTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeFeedTab() {
    final activeFilter =
        context.watch<HomeSearchFilterViewModel>().currentFilter;
    final uid = context.read<AuthViewModel>().user?.uid;

    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeaderWidget(
              filter: activeFilter,
              onFilterTap: () => _openFilterScreen(activeFilter),
            ),
            if (uid != null) ...[
              const SizedBox(height: 16),
              _buildProfileCompletionBanner(uid),
            ],
            const SizedBox(height: 24),
            SuggestedProfilesSectionWidget(
              onViewProfile: _openSuggestedProfile,
              onInviteTap: _showInviteBottomSheet,
            ),
            const SizedBox(height: 32),
            PostsFeedSectionWidget(onViewPost: _openPostDetail),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionBanner(String uid) {
    return StreamBuilder<UserModel?>(
      stream: context
          .read<UserProfileViewModel>()
          .getUserProfileStream(uid)
          .map((snapshot) {
        if (!snapshot.exists) return null;
        return UserModel.fromDocument(snapshot);
      }),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null || profile.profileCompleted) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.25),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoàn thiện hồ sơ để nhận gợi ý chính xác hơn',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bổ sung thói quen và tiêu chí ở ghép để RoomMate tìm người phù hợp hơn cho bạn.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: 170,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CompleteProfileFlowScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('Cập nhật ngay', style: AppTextStyles.buttonSm),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() => buildBottomNavLegacy();

  Widget buildBottomNavLegacy() {
    const items = [
      _NavItemData(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Trang chủ',
      ),
      _NavItemData(
        icon: Icons.description_outlined,
        activeIcon: Icons.description_rounded,
        label: 'Yêu cầu',
      ),
      _NavItemData(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: 'Nhắn tin',
      ),
      _NavItemData(
        icon: Icons.wallet_outlined,
        activeIcon: Icons.wallet_rounded,
        label: 'Chi tiêu',
      ),
      _NavItemData(
        icon: Icons.add_box_outlined,
        activeIcon: Icons.add_box_rounded,
        label: 'Đăng bài',
      ),
      _NavItemData(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Cá nhân',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (index == 0) {
                      setState(() => _selectedIndex = index);
                      context
                          .read<HomeSearchFilterViewModel>()
                          .resetFilter(clearSaved: false);
                    } else if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoommateRequestTabScreen(),
                        ),
                      );
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatListScreen(),
                        ),
                      );
                    } else if (index == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RoomGroupScreen(),
                        ),
                      );
                    } else if (index == 4) {
                      _openCreatePost();
                    } else if (index == 5) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserProfileScreen(),
                        ),
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.accent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                          if (index == 1)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Consumer<RoommateRequestViewModel>(
                                builder: (context, vm, _) {
                                  final count = vm.pendingCount;
                                  if (count == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return _NavBadge(label: count > 9 ? '9+' : '$count');
                                },
                              ),
                            ),
                          if (index == 2)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: StreamBuilder<List<ChatConversationModel>>(
                                stream: _getUnreadConversationsStream(),
                                builder: (context, snapshot) {
                                  final totalUnread = (snapshot.data ?? [])
                                      .fold<int>(
                                        0,
                                        (acc, c) => acc + c.unreadCount,
                                      );
                                  if (totalUnread == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return _NavBadge(
                                    label: totalUnread > 9
                                        ? '9+'
                                        : '$totalUnread',
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav helpers ────────────────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavBadge extends StatelessWidget {
  final String label;
  const _NavBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
