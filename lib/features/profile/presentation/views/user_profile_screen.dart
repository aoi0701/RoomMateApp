import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roommateapp/features/post/presentation/views/my_posts_screen.dart';
import 'package:roommateapp/features/roommate/presentation/viewmodels/roommate_request_viewmodel.dart';
import 'package:roommateapp/features/roommate/presentation/views/received_requests_screen.dart';

import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/views/login_screen.dart';
import '../../../home/presentation/viewmodels/roommate_profile_viewmodel.dart';
import '../../data/models/profile_habit_model.dart';
import '../../data/models/user_model.dart';
import '../viewmodels/user_profile_viewmodel.dart';
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
  static const Color primaryColor = Color(0xFF2F6BFF);
  static const Color backgroundColor = Color(0xFFF5F6FA);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color lightBlue = Color(0xFFEAF1FF);
  static const Color softMint = Color(0xFFE7F8F3);
  static const Color cardShadow = Color(0x14000000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RoommateRequestViewModel>().ensureReceivedRequestsListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final profileVm = context.read<UserProfileViewModel>();
    final currentUser = authVm.user;

    if (currentUser == null) {
      return const LoginScreen();
    }

    final viewedUserId = widget.userId ?? currentUser.uid;
    final isOwnProfile =
        widget.userId == null || widget.userId == currentUser.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: profileVm.getUserProfileStream(viewedUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Không thể tải hồ sơ: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text('Không tìm thấy thông tin người dùng'),
              );
            }

            final user = UserModel.fromDocument(snapshot.data!);
            final fullName = user.fullName.trim().isNotEmpty
                ? user.fullName.trim()
                : 'Chưa cập nhật';
            final email = user.email.trim().isNotEmpty
                ? user.email.trim()
                : (isOwnProfile
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
              if (user.occupation.trim().isEmpty && gender != 'Chưa cập nhật')
                gender,
            ];
            final subtitle = user.role == 'admin'
                ? 'Quản trị viên'
                : subtitleParts.isNotEmpty
                    ? subtitleParts.join(', ')
                    : 'Thành viên RoomMate';

            return StreamBuilder<bool>(
              stream: profileVm.hasUserPostsStream(viewedUserId),
              builder: (context, postSnapshot) {
                if (postSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final hasPosts = postSnapshot.data ?? false;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(isOwnProfile: isOwnProfile),
                      const SizedBox(height: 18),
                      _buildHeroProfile(
                        fullName: fullName,
                        subtitle: subtitle,
                      ),
                      if (!isOwnProfile && widget.matchPercentage != null) ...[
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
                      const SizedBox(height: 18),
                      _buildLifestyleSection(
                        user.habits,
                        canEdit: isOwnProfile,
                      ),
                      const SizedBox(height: 18),
                      _buildRoommateCriteriaSection(user.roommateCriteria),
                      if (isOwnProfile) ...[
                        const SizedBox(height: 22),
                        const Text(
                          'Quản lý',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
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
                            _ManageItem(
                              icon: Icons.mark_email_unread_outlined,
                              title: 'Yêu cầu ở ghép',
                              subtitle: 'Theo dõi các yêu cầu bạn đã nhận',
                              showBadge: true,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ReceivedRequestsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        if (!hasPosts) ...[
                          const SizedBox(height: 16),
                          _buildStatusNote(),
                        ],
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authVm.isLoading
                                ? null
                                : () async {
                                    await context.read<AuthViewModel>().logout();

                                    if (!context.mounted) return;

                                    final error =
                                        context.read<AuthViewModel>().errorMessage;
                                    if (error != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(error)),
                                      );
                                    } else {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE74C3C),
                              foregroundColor: Colors.white,
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
                                : const Text(
                                    'Đăng xuất',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
      bottomNavigationBar: isOwnProfile
          ? BottomNavigationBar(
              currentIndex: 4,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                if (index == 4) return;
                Navigator.pop(context);
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
                  icon: Icon(Icons.bookmark_border),
                  activeIcon: Icon(Icons.bookmark),
                  label: 'Đã lưu',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Nhắn tin',
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

  Widget _buildTopBar({required bool isOwnProfile}) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: cardShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textPrimary,
              size: 20,
            ),
          ),
        ),
        Expanded(
          child: Text(
            isOwnProfile ? 'Hồ sơ Cá nhân' : 'Hồ sơ người đăng',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
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
        color: lightBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.percent_rounded,
            color: primaryColor,
            size: 26,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tỉ lệ phù hợp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroProfile({
    required String fullName,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: cardShadow,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 54,
              color: primaryColor,
            ),
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
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF173A6A),
                        ),
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                    height: 1.35,
                  ),
                ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: cardShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin hồ sơ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Thông tin liên hệ',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 7,
                child: _ContactLine(
                  icon: Icons.email_outlined,
                  value: email,
                ),
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
          const Divider(height: 1),
          const SizedBox(height: 18),
          const Text(
            'Thông tin cơ bản',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
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
                child: _BasicInfoLine(
                  icon: Icons.wc_outlined,
                  value: gender,
                ),
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
            const Expanded(
              child: Text(
                'Thói quen',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ),
            if (canEdit)
              TextButton(
                onPressed: _openEditHabits,
                child: const Text(
                  'Chỉnh sửa',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
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

  Widget _buildHabitsEmptyState({required bool canEdit}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: cardShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thói quen',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cập nhật thói quen để đề xuất tiêu chí bạn cùng phòng phù hợp hơn.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: textSecondary,
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _openEditHabits,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              child: const Text(
                'Thêm thói quen',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoommateCriteriaSection(List<String> criteria) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: cardShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiêu chí bạn cùng phòng',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (criteria.isEmpty)
            const Text(
              'Chưa có tiêu chí nào. Hãy thêm thói quen để hệ thống tự động đồng bộ.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: textSecondary,
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
                        color: Color(0xFF8CC56D),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
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

  Widget _buildIntroductionSection(String fullName, String bio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giới thiệu',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            bio.trim().isNotEmpty
                ? bio.trim()
                : 'Chào các bạn! Mình là $fullName, tính tình cởi mở và thích chia sẻ. Mong tìm được người bạn cùng phòng vui tính, sạch sẽ và có lịch sinh hoạt phù hợp.',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: textPrimary,
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
    final success = await vm.sendInvite(targetUserId: targetUserId);
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

  Widget _buildInviteActionBar(String viewedUserId) {
    final inviteVm = context.watch<RoommateProfileViewModel>();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng nhắn tin sẽ cập nhật sau'),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Nhắn tin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: inviteVm.isInviting ? null : () => _sendInvite(viewedUserId),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: inviteVm.isInviting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Gửi lời mời ở ghép',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    final pendingCount = context.watch<RoommateRequestViewModel>().pendingCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, color: primaryColor, size: 28),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.showBadge && pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          pendingCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 30,
                      color: textSecondary,
                    ),
                  ],
                ),
                onTap: item.onTap,
              ),
              if (index != items.length - 1)
                const Divider(height: 1, indent: 18, endIndent: 18),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatusNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softMint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Bạn chưa có bài đăng nào. Khi đăng bài, hệ thống vẫn sẽ hiển thị đầy đủ mục Bài đăng của tôi và Yêu cầu ở ghép để bạn quản lý thuận tiện.',
        style: TextStyle(
          fontSize: 15,
          color: textPrimary,
          height: 1.5,
        ),
      ),
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
        Icon(
          icon,
          color: _UserProfileScreenState.textSecondary,
          size: 24,
        ),
        const SizedBox(width: 10),
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _UserProfileScreenState.textPrimary,
                height: 1.2,
              ),
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

  const _BasicInfoLine({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _UserProfileScreenState.lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _UserProfileScreenState.primaryColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _UserProfileScreenState.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHabitChip extends StatelessWidget {
  final ProfileHabitModel habit;

  const _ProfileHabitChip({
    required this.habit,
  });

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
            color: _UserProfileScreenState.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            habit.icon,
            color: habit.foregroundColor,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              habit.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _UserProfileScreenState.textPrimary,
                height: 1.25,
              ),
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
  final bool showBadge;

  _ManageItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showBadge = false,
  });
}
