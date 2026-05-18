import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/helpers/home_formatters.dart';
import '../../data/models/room_search_filter_model.dart';
import '../../data/models/roommate_profile_model.dart';
import '../viewmodels/home_search_filter_viewmodel.dart';
import '../viewmodels/roommate_profile_viewmodel.dart';
import 'room_search_filter_screen.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../chat/presentation/viewmodels/chat_viewmodel.dart';
import '../../../chat/presentation/views/chat_list_screen.dart';
import '../../../roommate/presentation/views/roommate_request_tab_screen.dart';
import '../../../post/data/models/post_model.dart';
import '../../../post/presentation/viewmodels/post_list_viewmodel.dart';
import '../../../post/presentation/views/create_post_screen.dart';
import '../../../post/presentation/views/post_detail_screen.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../../profile/presentation/views/user_profile_screen.dart';
import '../../../room_group/presentation/views/room_group_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeSearchFilterViewModel>().resetFilter(clearSaved: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PostModel> _applyFilters(
    List<PostModel> posts,
    RoomSearchFilterModel filter,
  ) {
    return posts.where(filter.matchesPost).toList();
  }

  static String formatMoney(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng ☀️';
    if (hour < 18) return 'Chào buổi chiều 🌤';
    return 'Chào buổi tối 🌙';
  }

  Future<void> _openFilterScreen(RoomSearchFilterModel filter) async {
    final result = await Navigator.push<RoomSearchFilterModel>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomSearchFilterScreen(initialFilter: filter),
      ),
    );
    if (result != null && mounted) {
      context.read<HomeSearchFilterViewModel>().updateFilterLocally(result);
    }
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
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
        child: _InviteSheet(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postVm = context.read<PostListViewModel>();
    final filterVm = context.watch<HomeSearchFilterViewModel>();
    final roommateVm = context.watch<RoommateProfileViewModel>();
    final activeFilter = filterVm.currentFilter;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(activeFilter),
                    const SizedBox(height: 24),
                    _buildSuggestedProfilesSection(roommateVm),
                    const SizedBox(height: 32),
                    _buildFeaturedPostsSection(postVm, activeFilter),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RoomSearchFilterModel filter) {
    _searchController.value = TextEditingValue(
      text: filter.hasActiveFilters ? filter.summaryText : '',
      selection: TextSelection.collapsed(
        offset: filter.hasActiveFilters ? filter.summaryText.length : 0,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF4756D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greetingText(),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tìm bạn ở ghép',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _openFilterScreen(filter),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      filter.hasActiveFilters
                          ? filter.summaryText
                          : 'Vị trí, ngân sách...',
                      style: GoogleFonts.plusJakartaSans(
                        color: filter.hasActiveFilters
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                        fontSize: 14,
                        fontWeight: filter.hasActiveFilters
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: AppTextStyles.h2),
    );
  }

  Widget _buildSuggestedProfilesSection(RoommateProfileViewModel roommateVm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Gợi ý bạn ở ghép'),
        const SizedBox(height: 16),
        StreamBuilder<List<RoommateProfileModel>>(
          stream: roommateVm.suggestedProfilesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _ProfileCardShimmer(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildInlineMessage(
                  Icons.error_outline_rounded,
                  'Không tải được gợi ý',
                  '${snapshot.error}',
                ),
              );
            }

            final profiles = snapshot.data ?? const <RoommateProfileModel>[];
            if (profiles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildInlineMessage(
                  Icons.person_search_outlined,
                  'Chưa có hồ sơ phù hợp',
                  'Cập nhật thói quen và tiêu chí trong hồ sơ để nhận gợi ý.',
                ),
              );
            }

            return SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: profiles.take(6).length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  final invited = roommateVm.isInvited(profile.userId);
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < profiles.take(6).length - 1 ? 16 : 0,
                    ),
                    child: _SuggestedProfileCard(
                      profile: profile,
                      onViewDetail: () => _openSuggestedProfile(profile),
                      isInvited: invited,
                      onInviteTap:
                          invited ? null : () => _showInviteBottomSheet(profile),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedPostsSection(
    PostListViewModel postVm,
    RoomSearchFilterModel activeFilter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Bài đăng nổi bật'),
        const SizedBox(height: 16),
        StreamBuilder<List<PostModel>>(
          stream: postVm.postsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _PostCardShimmer(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildInlineMessage(
                  Icons.error_outline_rounded,
                  'Không tải được bài đăng',
                  '${snapshot.error}',
                ),
              );
            }

            final allPosts = snapshot.data ?? const <PostModel>[];
            final posts = _applyFilters(allPosts, activeFilter);

            if (posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildInlineMessage(
                  Icons.home_work_outlined,
                  'Chưa có bài đăng nào',
                  'Khi có người đăng bài, nội dung sẽ hiển thị tại đây.',
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _FeaturedPostCard(
                  post: post,
                  onViewDetail: () => _openPostDetail(post),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildInlineMessage(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = const [
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
                      context
                          .read<HomeSearchFilterViewModel>()
                          .resetFilter(clearSaved: true);
                      _searchController.clear();
                      setState(() => _selectedIndex = index);
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
                          // Unread badge for Nhắn tin tab (index 2)
                          if (index == 2)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: StreamBuilder<List<dynamic>>(
                                stream: context
                                    .read<ChatViewModel>()
                                    .conversationsStream,
                                builder: (context, snapshot) {
                                  final convs = snapshot.data ?? [];
                                  final totalUnread = convs.fold<int>(
                                    0,
                                    (acc, c) {
                                      // ignore: avoid_dynamic_calls
                                      final count = (c as dynamic).unreadCount
                                          as int? ??
                                          0;
                                      return acc + count;
                                    },
                                  );
                                  if (totalUnread == 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        totalUnread > 9
                                            ? '9+'
                                            : '$totalUnread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
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
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
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

// ── Profile card ──────────────────────────────────────────────────────────────

class _SuggestedProfileCard extends StatelessWidget {
  final RoommateProfileModel profile;
  final VoidCallback onViewDetail;
  final VoidCallback? onInviteTap;
  final bool isInvited;

  const _SuggestedProfileCard({
    required this.profile,
    required this.onViewDetail,
    required this.isInvited,
    this.onInviteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(
                name: profile.displayName,
                avatarUrl: profile.avatarUrl,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLg,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _MatchBadge(percentage: profile.matchPercentage),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.bio.isNotEmpty
                ? profile.bio
                : 'Đang tìm bạn ở ghép phù hợp.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: profile.habits
                .take(3)
                .map((item) => _TagChip(label: item))
                .toList(),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: onViewDetail,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: AppTextStyles.buttonSm.copyWith(height: 1.2),
                      minimumSize: const Size(0, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Xem chi tiết'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: onInviteTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isInvited
                        ? AppColors.successText
                        : AppColors.primary,
                    side: BorderSide(
                      color: isInvited
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    backgroundColor: isInvited
                        ? AppColors.successSurface
                        : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(44, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Icon(
                    isInvited
                        ? Icons.check_rounded
                        : Icons.person_add_alt_1_outlined,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Featured post card ────────────────────────────────────────────────────────

class _FeaturedPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onViewDetail;

  const _FeaturedPostCard({required this.post, required this.onViewDetail});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewDetail,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 8,
                child: post.imageUrl.trim().isNotEmpty
                    ? Image.network(
                        post.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) =>
                            _PostImageFallback(title: post.title),
                      )
                    : _PostImageFallback(title: post.title),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PostOwnerHeader(post: post),
                  const SizedBox(height: 12),
                  Text(
                    post.title.isNotEmpty
                        ? post.title
                        : 'Bài đăng tìm bạn ở ghép',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3,
                  ),
                  if (post.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      post.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _buildPostTags(post),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: onViewDetail,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: AppTextStyles.buttonSm.copyWith(height: 1.2),
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Xem chi tiết'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostOwnerHeader extends StatelessWidget {
  final PostModel post;
  const _PostOwnerHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final profileVm = context.read<UserProfileViewModel>();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileVm.getUserProfileStream(post.ownerId),
      builder: (context, snapshot) {
        final user = snapshot.hasData && snapshot.data!.exists
            ? UserModel.fromDocument(snapshot.data!)
            : null;
        final displayName = formatLastTwoWords(user?.fullName ?? '');
        final displayAddress = formatReadableAddress(
          fullAddress: user?.address ?? '',
          preferredLocation: user?.preferredLocation ?? '',
          district: post.district,
          province: post.province,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppAvatar(
              name: displayName,
              avatarUrl: user?.avatarUrl ?? '',
              size: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label,
                  ),
                  Text(
                    displayAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                post.price > 0
                    ? '${_UserHomeScreenState.formatMoney(post.price)}đ'
                    : 'Thỏa thuận',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Shimmer placeholders ──────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, val) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFFE2E8F0),
            const Color(0xFFF1F5F9),
            _animation.value,
          ),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ProfileCardShimmer extends StatelessWidget {
  const _ProfileCardShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (ctx, idx) => Container(
          width: 260,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _ShimmerBox(
                    width: 52,
                    height: 52,
                    borderRadius: BorderRadius.all(Radius.circular(26)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 120, height: 14),
                      const SizedBox(height: 8),
                      _ShimmerBox(width: 80, height: 12),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ShimmerBox(width: double.infinity, height: 12),
              const SizedBox(height: 8),
              _ShimmerBox(width: 180, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCardShimmer extends StatelessWidget {
  const _PostCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _ShimmerBox(
              width: double.infinity,
              height: 180,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _ShimmerBox(
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBox(width: 120, height: 13),
                        const SizedBox(height: 6),
                        _ShimmerBox(width: 80, height: 11),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _ShimmerBox(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                _ShimmerBox(width: 200, height: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _MatchBadge extends StatelessWidget {
  final int percentage;
  const _MatchBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$percentage%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'phù hợp',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PostImageFallback extends StatelessWidget {
  final String title;
  const _PostImageFallback({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.accent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.home_work_outlined,
              color: AppColors.primary,
              size: 36,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _buildPostTags(PostModel post) {
  final tags = <String>[];
  if (post.amenities.isNotEmpty) tags.addAll(post.amenities.take(2));
  if (tags.isEmpty && post.roomType.trim().isNotEmpty) tags.add(post.roomType.trim());
  if (tags.length < 3 && post.area > 0) tags.add('${post.area} m²');
  if (tags.length < 3 && post.capacity > 0) tags.add('${post.capacity} người');
  return tags.take(3).map((item) => _TagChip(label: item)).toList();
}

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

// ── Invite bottom sheet ───────────────────────────────────────────────────────

class _InviteSheet extends StatefulWidget {
  final RoommateProfileModel profile;
  const _InviteSheet({required this.profile});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<RoommateProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final targetName = widget.profile.displayName;

    final success = await vm.sendInvite(
      targetUserId: widget.profile.userId,
      targetName: widget.profile.fullName,
      targetAvatar: widget.profile.avatarUrl,
      message: _msgController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã gửi lời mời đến $targetName'
              : (vm.errorMessage ?? 'Không thể gửi lời mời'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoommateProfileViewModel>(
      builder: (context, vm, _) {
        final isLoading = vm.isInviting;
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Profile info row
              Row(
                children: [
                  AppAvatar(
                    name: widget.profile.displayName,
                    avatarUrl: widget.profile.avatarUrl,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.profile.displayName,
                            style: AppTextStyles.labelLg),
                        const SizedBox(height: 2),
                        Text(widget.profile.address,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.profile.matchPercentage}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'phù hợp',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Lời nhắn (tuỳ chọn)', style: AppTextStyles.label),
              const SizedBox(height: 10),
              TextField(
                controller: _msgController,
                enabled: !isLoading,
                maxLines: 3,
                maxLength: 200,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText:
                      'Xin chào! Mình muốn tìm bạn ở ghép cùng...',
                  hintStyle:
                      AppTextStyles.body.copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  counterStyle: AppTextStyles.caption,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    textStyle: AppTextStyles.button,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Gửi lời mời'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Huỷ', style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondary,
                  )),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
