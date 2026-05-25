import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:roommateapp/features/chat/presentation/viewmodels/chat_viewmodel.dart';
import 'package:roommateapp/features/chat/presentation/views/chat_detail_screen.dart';
import 'package:roommateapp/features/chat/presentation/views/chat_list_screen.dart';
import 'package:roommateapp/features/home/presentation/views/user_home_screen.dart';
import 'package:roommateapp/features/post/presentation/views/create_post_screen.dart';
import 'package:roommateapp/features/post/presentation/views/my_posts_screen.dart';
import 'package:roommateapp/features/room_group/presentation/views/room_group_screen.dart';
import 'package:roommateapp/features/roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import 'package:roommateapp/features/roommate/presentation/views/roommate_request_tab_screen.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/utils/logout_helper.dart';
import '../../../auth/presentation/views/login_screen.dart';
import '../../../home/presentation/viewmodels/roommate_profile_viewmodel.dart';
import '../../data/models/profile_habit_model.dart';
import '../../data/models/user_model.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import 'complete_profile_flow_screen.dart';
import 'edit_habits_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String? userId;
  final int? matchPercentage;
  final bool showInviteAction;

  const UserProfileScreen({
    super.key,
    this.userId,
    this.matchPercentage,
    this.showInviteAction = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _viewedUserName = '';
  String _viewedUserAvatar = '';

  RoommateRequestViewModel? _maybeRoommateRequestViewModel() {
    try {
      return context.read<RoommateRequestViewModel>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  UserProfileViewModel? _maybeUserProfileViewModel() {
    try {
      return context.read<UserProfileViewModel>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  bool _isCurrentUserProfile(String currentUserId) {
    return widget.userId == null || widget.userId == currentUserId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeRoommateRequestViewModel()?.ensureReceivedRequestsListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final currentUser = authVm.user;
    final profileVm = _maybeUserProfileViewModel();

    if (currentUser == null || profileVm == null) {
      return const LoginScreen();
    }

    final viewedUserId = widget.userId ?? currentUser.uid;
    final isCurrentUserProfile = _isCurrentUserProfile(currentUser.uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: profileVm.getUserProfileStream(viewedUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Không thể tải hồ sơ: ${snapshot.error}',
                  style: AppTextStyles.body,
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  'Không tìm thấy thông tin người dùng',
                  style: AppTextStyles.body,
                ),
              );
            }

            final user = UserModel.fromDocument(snapshot.data!);
            if (_viewedUserName != user.fullName ||
                _viewedUserAvatar != user.avatarUrl) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _viewedUserName = user.fullName;
                    _viewedUserAvatar = user.avatarUrl;
                  });
                }
              });
            }
            final fullName = user.fullName.trim().isNotEmpty
                ? user.fullName.trim()
                : 'Chưa cập nhật';
            final email = user.email.trim().isNotEmpty
                ? user.email.trim()
                : (isCurrentUserProfile
                    ? (currentUser.email ?? 'Chưa cập nhật')
                    : 'Chưa cập nhật');
            final phone = user.phone.trim().isNotEmpty
                ? user.phone.trim()
                : 'Chưa cập nhật';
            final address = user.address.trim().isNotEmpty
                ? user.address.trim()
                : 'Chưa cập nhật';
            final gender = user.gender.trim().isNotEmpty
                ? user.gender.trim()
                : 'Chưa cập nhật';
            final subtitleParts = <String>[
              if (user.age != null) '${user.age}',
              if (user.occupation.trim().isNotEmpty) user.occupation.trim(),
            ];
            final subtitle = user.role == 'admin'
                ? 'Quản trị viên'
                : subtitleParts.isNotEmpty
                    ? subtitleParts.join(', ')
                    : '';

            return StreamBuilder<bool>(
              stream: profileVm.hasUserPostsStream(viewedUserId),
              builder: (context, postSnapshot) {
                if (postSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final hasPosts = postSnapshot.data ?? false;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(isCurrentUserProfile: isCurrentUserProfile),
                      const SizedBox(height: 18),
                      _buildHeroProfile(
                        fullName: fullName,
                        subtitle: subtitle,
                        avatarUrl: user.avatarUrl.isNotEmpty ? user.avatarUrl : null,
                      ),
                      if (!isCurrentUserProfile && widget.matchPercentage != null) ...[
                        const SizedBox(height: 14),
                        _buildMatchBanner(widget.matchPercentage!),
                      ],
                      const SizedBox(height: 18),
                      _buildCombinedInfoCard(
                        email: email,
                        phone: phone,
                        address: address,
                        gender: gender,
                      ),
                      if (isCurrentUserProfile && !user.profileCompleted) ...[
                        const SizedBox(height: 18),
                        _buildProfileCompletionCard(),
                      ],
                      const SizedBox(height: 18),
                      _buildLifestyleSection(user.habits, canEdit: isCurrentUserProfile),
                      const SizedBox(height: 18),
                      _buildRoommateCriteriaSection(user.roommateCriteria),
                      if (isCurrentUserProfile) ...[
                        const SizedBox(height: 22),
                        Text('Quản lý', style: AppTextStyles.h1),
                        const SizedBox(height: 14),
                        _buildManageCard(
                          context,
                          items: [
                            _ManageItem(
                              icon: Icons.article_outlined,
                              title: 'Bài đăng của tôi',
                              subtitle: hasPosts
                                  ? 'Xem và quản lý các bài đăng của bạn'
                                  : 'Hiện chưa có bài đăng nào',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyPostsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authVm.isLoading
                                ? null
                                : () async {
                                    await performLogout(context);
                                    if (!context.mounted) return;
                                    final error =
                                        context.read<AuthViewModel>().errorMessage;
                                    if (error != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.45),
                              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: authVm.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Đăng xuất', style: AppTextStyles.button),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: isCurrentUserProfile
          ? BottomNavigationBar(
              currentIndex: 5,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              backgroundColor: AppColors.surface,
              elevation: 0,
              selectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              onTap: (index) {
                if (index == 5) return;
                switch (index) {
                  case 0:
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                      (route) => false,
                    );
                    break;
                  case 1:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoommateRequestTabScreen(),
                      ),
                    );
                    break;
                  case 2:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    );
                    break;
                  case 3:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RoomGroupScreen()),
                    );
                    break;
                  case 4:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                    );
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Trang chủ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.description_outlined),
                  activeIcon: Icon(Icons.description),
                  label: 'Yêu cầu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  activeIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Nhắn tin',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.wallet_outlined),
                  activeIcon: Icon(Icons.wallet),
                  label: 'Chi tiêu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_box_outlined),
                  activeIcon: Icon(Icons.add_box),
                  label: 'Đăng bài',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Cá nhân',
                ),
              ],
            )
          : widget.showInviteAction
              ? _buildInviteActionBar(viewedUserId)
              : null,
    );
  }

  Widget _buildTopBar({required bool isCurrentUserProfile}) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        Expanded(
          child: Text(
            isCurrentUserProfile ? 'Hồ sơ Cá nhân' : 'Hồ sơ người đăng',
            textAlign: TextAlign.center,
            style: AppTextStyles.h2,
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _buildMatchBanner(int percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.percent_rounded, color: AppColors.primary, size: 26),
          const SizedBox(width: 10),
          Expanded(child: Text('Tỉ lệ phù hợp', style: AppTextStyles.labelLg)),
          Text(
            '$percentage%',
            style: AppTextStyles.h1.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroProfile({
    required String fullName,
    required String subtitle,
    String? avatarUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar(
            name: fullName,
            avatarUrl: avatarUrl,
            size: 90,
            showBorder: true,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.h1.copyWith(fontSize: 22),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedInfoCard({
    required String email,
    required String phone,
    required String address,
    required String gender,
  }) {
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin hồ sơ', style: AppTextStyles.h2),
          const SizedBox(height: 18),
          Text('Thông tin liên hệ', style: AppTextStyles.labelLg),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 7,
                child: _ContactLine(icon: Icons.email_outlined, value: email),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: _ContactLine(
                  icon: Icons.phone_outlined,
                  value: phone,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 18),
          Text('Thông tin cơ bản', style: AppTextStyles.labelLg),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BasicInfoLine(
                  icon: Icons.location_on_outlined,
                  value: address,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BasicInfoLine(icon: Icons.wc_outlined, value: gender),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleSection(
    List<String> selectedHabits, {
    required bool canEdit,
  }) {
    final selectedItems = selectedHabits
        .map(ProfileHabitCatalog.findById)
        .whereType<ProfileHabitModel>()
        .toList();

    if (selectedItems.isEmpty) {
      return _buildHabitsEmptyState(canEdit: canEdit);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Thói quen', style: AppTextStyles.h1)),
            if (canEdit)
              TextButton(
                onPressed: _openEditHabits,
                child: Text(
                  'Chỉnh sửa',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: selectedItems
              .map((item) => _ProfileHabitChip(habit: item))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildProfileCompletionCard() {
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hồ sơ chưa hoàn thiện', style: AppTextStyles.h2),
          const SizedBox(height: 10),
          Text(
            'Bổ sung thông tin cơ bản, thói quen và tiêu chí ở ghép để tăng chất lượng gợi ý bạn cùng phòng.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Hoàn thiện hồ sơ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompleteProfileFlowScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsEmptyState({required bool canEdit}) {
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thói quen', style: AppTextStyles.h2),
          const SizedBox(height: 10),
          Text(
            'Cập nhật thói quen để đề xuất tiêu chí bạn cùng phòng phù hợp hơn.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 16),
            AppSecondaryButton(label: 'Thêm thói quen', onTap: _openEditHabits),
          ],
        ],
      ),
    );
  }

  Widget _buildRoommateCriteriaSection(List<String> criteria) {
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tiêu chí bạn cùng phòng', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          if (criteria.isEmpty)
            Text(
              'Chưa có tiêu chí nào. Hãy thêm thói quen để hệ thống tự động đồng bộ.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            )
          else
            ...criteria.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item, style: AppTextStyles.label)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditHabits() async {
    final authVm = context.read<AuthViewModel>();
    final profileVm = context.read<UserProfileViewModel>();
    final uid = authVm.user?.uid;
    if (uid == null) return;

    final user = await profileVm.getUserProfile(uid);
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditHabitsScreen(
          initialHabits: user?.habits ?? const [],
        ),
      ),
    );
  }

  Future<void> _sendInvite(String targetUserId) async {
    final vm = context.read<RoommateProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await vm.sendInvite(
      targetUserId: targetUserId,
      targetName: _viewedUserName,
      targetAvatar: _viewedUserAvatar,
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã gửi lời mời đến ${_viewedUserName.isNotEmpty ? _viewedUserName : "người dùng"}'
              : (vm.errorMessage ?? 'Không thể gửi lời mời'),
        ),
      ),
    );
  }

  Widget _buildInviteActionBar(String viewedUserId) {
    final inviteVm = context.watch<RoommateProfileViewModel>();
    final authVm = context.read<AuthViewModel>();
    final currentUserId = authVm.user?.uid ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppSecondaryButton(
              label: 'Nhắn tin',
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              onTap: () {
                final chatVm = context.read<ChatViewModel>();
                final _ = chatVm.getConversationId(
                    currentUserId, viewedUserId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      otherUserId: viewedUserId,
                      otherUserName: _viewedUserName,
                      otherUserAvatar: _viewedUserAvatar,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppPrimaryButton(
              label: 'Gửi lời mời ở ghép',
              isLoading: inviteVm.isInviting,
              onTap: inviteVm.isInviting ? null : () => _sendInvite(viewedUserId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageCard(
    BuildContext context, {
    required List<_ManageItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];

          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: AppColors.primary, size: 24),
                ),
                title: Text(item.title, style: AppTextStyles.labelLg),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
                onTap: item.onTap,
              ),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: AppColors.border,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Widget child;
  const _ProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String value;
  final TextAlign textAlign;

  const _ContactLine({
    required this.icon,
    required this.value,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: textAlign == TextAlign.right
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              textAlign: textAlign,
              style: AppTextStyles.body,
            ),
          ),
        ),
      ],
    );
  }
}

class _BasicInfoLine extends StatelessWidget {
  final IconData icon;
  final String value;

  const _BasicInfoLine({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHabitChip extends StatelessWidget {
  final ProfileHabitModel habit;
  const _ProfileHabitChip({required this.habit});

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 48) / 2;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: habit.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(habit.icon, color: habit.foregroundColor, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              habit.label,
              style: AppTextStyles.label.copyWith(height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ManageItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
