import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/helpers/home_formatters.dart';
import '../../data/models/room_search_filter_model.dart';
import '../../data/models/roommate_profile_model.dart';
import '../viewmodels/home_search_filter_viewmodel.dart';
import '../viewmodels/roommate_profile_viewmodel.dart';
import 'room_search_filter_screen.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../notification/presentation/viewmodels/notification_viewmodel.dart';
import '../../../notification/presentation/views/notification_screen.dart';
import '../../../post/data/models/post_model.dart';
import '../../../post/presentation/viewmodels/post_list_viewmodel.dart';
import '../../../post/presentation/views/create_post_screen.dart';
import '../../../post/presentation/views/post_detail_screen.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../../profile/presentation/views/user_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  static const Color primaryBlue = AppColors.primary;
  static const Color headerBlue = AppColors.primary;
  static const Color bgColor = AppColors.background;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color softMint = Color(0xFFE7F8F3);

  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeSearchFilterViewModel>().resetFilter(clearSaved: true);
      final userId = context.read<AuthViewModel>().user?.uid;
      if (userId != null) {
        context.read<NotificationViewModel>().listenToNotifications(userId);
      }
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
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
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

  Future<void> _sendInvite(RoommateProfileModel profile) async {
    final vm = context.read<RoommateProfileViewModel>();
    final success = await vm.sendInvite(targetUserId: profile.userId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã gửi lời mời ở ghép'
              : (vm.errorMessage ?? 'Không thể gửi lời mời'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postVm = context.read<PostListViewModel>();
    final filterVm = context.watch<HomeSearchFilterViewModel>();
    final roommateVm = context.read<RoommateProfileViewModel>();
    final activeFilter = filterVm.currentFilter;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 128),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(activeFilter),
                        const SizedBox(height: 18),
                        _buildSuggestedProfilesSection(roommateVm),
                        const SizedBox(height: 28),
                        _buildFeaturedPostsSection(postVm, activeFilter),
                      ],
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 104,
              child: _CreatePostFab(onTap: _openCreatePost),
            ),
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
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        color: headerBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Consumer<NotificationViewModel>(
                builder: (context, notifVm, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      ),
                    ),
                    if (notifVm.unreadCount > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            notifVm.unreadCount > 99
                                ? '99+'
                                : '${notifVm.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            _greetingText(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tìm bạn ở ghép',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: textSecondary, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    readOnly: true,
                    onTap: () => _openFilterScreen(filter),
                    decoration: const InputDecoration(
                      hintText: 'Vị trí, ngân sách',
                      hintStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Icon(Icons.tune_rounded, color: primaryBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedProfilesSection(RoommateProfileViewModel roommateVm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý bạn ở ghép phù hợp',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<RoommateProfileModel>>(
            stream: roommateVm.suggestedProfilesStream,
            builder: (context, snapshot) {
              final profiles = snapshot.data ?? const <RoommateProfileModel>[];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildMessageCard(
                  Icons.error_outline,
                  'Không tải được gợi ý',
                  '${snapshot.error}',
                );
              }

              if (profiles.isEmpty) {
                return _buildMessageCard(
                  Icons.person_search_outlined,
                  'Chưa có hồ sơ phù hợp',
                  'Hãy cập nhật thói quen và tiêu chí trong hồ sơ để nhận gợi ý tốt hơn.',
                );
              }

              return SizedBox(
                height: 320,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: profiles.take(6).length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return _SuggestedProfileCard(
                      profile: profile,
                      onViewDetail: () => _openSuggestedProfile(profile),
                      onInviteTap: () => _sendInvite(profile),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPostsSection(
    PostListViewModel postVm,
    RoomSearchFilterModel activeFilter,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bài đăng nổi bật',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<PostModel>>(
            stream: postVm.postsStream,
            builder: (context, snapshot) {
              final allPosts = snapshot.data ?? const <PostModel>[];
              final posts = _applyFilters(allPosts, activeFilter);

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildMessageCard(
                  Icons.error_outline,
                  'Không tải được bài đăng',
                  '${snapshot.error}',
                );
              }

              if (posts.isEmpty) {
                return _buildMessageCard(
                  Icons.home_work_outlined,
                  'Chưa có bài đăng nào',
                  'Khi có người đăng bài, nội dung sẽ hiển thị tại đây.',
                );
              }

              return ListView.separated(
                itemCount: posts.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 18),
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
      ),
    );
  }

  Widget _buildMessageCard(IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 54, color: textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = const [
      {'icon': Icons.home_filled, 'label': 'Trang chủ'},
      {'icon': Icons.description_outlined, 'label': 'Yêu cầu'},
      {'icon': Icons.favorite_border, 'label': 'Đã lưu'},
      {'icon': Icons.chat_bubble_outline, 'label': 'Nhắn tin'},
      {'icon': Icons.person_outline, 'label': 'Cá nhân'},
    ];

    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          return _BottomNavItem(
            icon: items[index]['icon'] as IconData,
            label: items[index]['label'] as String,
            isActive: _selectedIndex == index,
            onTap: () {
              if (index == 0) {
                context
                    .read<HomeSearchFilterViewModel>()
                    .resetFilter(clearSaved: true);
                _searchController.clear();
                setState(() => _selectedIndex = index);
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserProfileScreen(),
                  ),
                );
              } else {
                setState(() => _selectedIndex = index);
              }
            },
          );
        }),
      ),
    );
  }
}

class _SuggestedProfileCard extends StatelessWidget {
  final RoommateProfileModel profile;
  final VoidCallback onViewDetail;
  final VoidCallback onInviteTap;

  const _SuggestedProfileCard({
    required this.profile,
    required this.onViewDetail,
    required this.onInviteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(
                name: profile.displayName,
                avatarUrl: profile.avatarUrl,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _UserHomeScreenState.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _UserHomeScreenState.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
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
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: _UserHomeScreenState.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.habits
                .take(3)
                .map((item) => _TagPill(label: item))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onViewDetail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _UserHomeScreenState.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Xem chi tiết',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onInviteTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _UserHomeScreenState.primaryBlue,
                  side: const BorderSide(
                    color: _UserHomeScreenState.primaryBlue,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_alt_1_outlined, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Mời',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onViewDetail;

  const _FeaturedPostCard({
    required this.post,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: post.imageUrl.trim().isNotEmpty
                    ? Image.network(
                        post.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _PostImageFallback(title: post.title),
                      )
                    : _PostImageFallback(title: post.title),
              ),
            ),
            const SizedBox(height: 14),
            _PostOwnerHeader(post: post),
            const SizedBox(height: 12),
            Text(
              post.title.isNotEmpty ? post.title : 'Bài đăng tìm bạn ở ghép',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _UserHomeScreenState.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.description.isNotEmpty ? post.description : post.location,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: _UserHomeScreenState.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildPostTags(post),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onViewDetail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _UserHomeScreenState.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Xem chi tiết',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onViewDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _UserHomeScreenState.primaryBlue,
                    side: const BorderSide(
                      color: _UserHomeScreenState.primaryBlue,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Nhắn tin',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileAvatar(
              name: displayName,
              avatarUrl: user?.avatarUrl ?? '',
              size: 56,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _UserHomeScreenState.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _UserHomeScreenState.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _UserHomeScreenState.lightBlue,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                post.price > 0
                    ? '${_UserHomeScreenState.formatMoney(post.price)}d'
                    : 'Thoa thuan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _UserHomeScreenState.primaryBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final double size;

  const _ProfileAvatar({
    required this.name,
    required this.avatarUrl,
    this.size = 68,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        ),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    final trimmedName = name.trim();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFDDEBFF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          trimmedName.isNotEmpty ? trimmedName.substring(0, 1) : 'U',
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: _UserHomeScreenState.primaryBlue,
          ),
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  final int percentage;

  const _MatchBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _UserHomeScreenState.lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'Phu hop',
            style: TextStyle(
              fontSize: 11,
              color: _UserHomeScreenState.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _UserHomeScreenState.primaryBlue,
            ),
          ),
        ],
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
      color: const Color(0xFFE8EEF9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _UserHomeScreenState.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> _buildPostTags(PostModel post) {
  final tags = <String>[];
  if (post.amenities.isNotEmpty) {
    tags.addAll(post.amenities.take(3));
  }
  if (tags.isEmpty && post.roomType.trim().isNotEmpty) {
    tags.add(post.roomType.trim());
  }
  if (tags.length < 3 && post.area > 0) {
    tags.add('${post.area} m2');
  }
  if (tags.length < 3 && post.capacity > 0) {
    tags.add('${post.capacity} nguoi');
  }

  return tags.take(3).map((item) => _TagPill(label: item)).toList();
}

class _CreatePostFab extends StatelessWidget {
  final VoidCallback onTap;

  const _CreatePostFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF8EDBCA),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.add, size: 42, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo bài đăng',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _UserHomeScreenState.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;

  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _UserHomeScreenState.softMint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _UserHomeScreenState.textPrimary,
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? _UserHomeScreenState.primaryBlue
        : _UserHomeScreenState.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
