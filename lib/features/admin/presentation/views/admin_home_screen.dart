import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../data/repositories/admin_repository.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/presentation/views/login_screen.dart';
import '../../../post/data/models/post_model.dart';
import '../../../profile/data/models/user_model.dart';
import '../../../roommate/data/models/roommate_request_model.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AdminRepository _adminRepository = AdminRepository();
  int _selectedIndex = 0;

  static const List<_AdminMenuItem> _menuItems = [
    _AdminMenuItem(
      label: 'Tổng quan',
      icon: Icons.space_dashboard_rounded,
      title: 'RoomMate',
      description: '',
    ),
    _AdminMenuItem(
      label: 'Người dùng',
      icon: Icons.groups_rounded,
      title: 'Quản lý người dùng',
      description: 'Danh sách thành viên mới.',
    ),
    _AdminMenuItem(
      label: 'Bài đăng',
      icon: Icons.home_work_rounded,
      title: 'Quản lý bài đăng',
      description: 'Theo dõi bài đăng mới, giá phòng và khu vực được tìm kiếm nhiều.',
    ),
    _AdminMenuItem(
      label: 'Yêu cầu',
      icon: Icons.mark_chat_unread_rounded,
      title: 'Quản lý yêu cầu',
      description: 'Giám sát các roommate request, mức độ phản hồi và trạng thái xử lý.',
    ),
  ];

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();

    if (!context.mounted) return;

    final error = context.read<AuthViewModel>().errorMessage;
    if (error == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1180;
    final selectedItem = _menuItems[_selectedIndex];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F7FB),
      drawer: isDesktop
          ? null
          : Drawer(
              child: _AdminSidebar(
                selectedIndex: _selectedIndex,
                onSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 284,
                child: _AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onSelected: (index) => setState(() => _selectedIndex = index),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(
                    isDesktop: isDesktop,
                    title: selectedItem.title,
                    isLoading: authVm.isLoading,
                    onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    onLogout: () => _logout(context),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _AdminBody(
                        selectedIndex: _selectedIndex,
                        repository: _adminRepository,
                      ),
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

class _AdminBody extends StatelessWidget {
  const _AdminBody({
    required this.selectedIndex,
    required this.repository,
  });

  final int selectedIndex;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 1:
        return _UsersSection(repository: repository);
      case 2:
        return _PostsSection(repository: repository);
      case 3:
        return _RequestsSection(repository: repository);
      case 0:
      default:
        return _DashboardSection(repository: repository);
    }
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.isDesktop,
    required this.title,
    required this.isLoading,
    required this.onMenuPressed,
    required this.onLogout,
  });

  final bool isDesktop;
  final String title;
  final bool isLoading;
  final VoidCallback onMenuPressed;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton(
                onPressed: onMenuPressed,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                ),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
          Expanded(
            child: Wrap(
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Color(0xFF0F766E),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm RoomMate...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: isLoading ? null : onLogout,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(isLoading ? 'Đang xử lý' : 'Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFF0F766E),
                  child: Icon(
                    Icons.house_siding_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'RoomMate',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'BẢNG ĐIỀU KHIỂN',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.3,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFFECDD3),
                  child: Icon(Icons.admin_panel_settings_rounded),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản trị RoomMate',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Trung tâm quản trị web',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'DASHBOARD',
              style: TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _AdminHomeScreenState._menuItems.length; i++) ...[
            _SidebarTile(
              item: _AdminHomeScreenState._menuItems[i],
              isSelected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thống kê RoomMate',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
} 

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _AdminMenuItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F766E) : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x220F766E),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RoomMateHeroCard(),
        const SizedBox(height: 24),
        StreamBuilder<int>(
          stream: repository.getUsersCountStream(),
          builder: (context, userSnapshot) {
            return StreamBuilder<int>(
              stream: repository.getPostsCountStream(),
              builder: (context, postSnapshot) {
                return StreamBuilder<int>(
                  stream: repository.getRequestsCountStream(),
                  builder: (context, requestSnapshot) {
                    if (userSnapshot.hasError ||
                        postSnapshot.hasError ||
                        requestSnapshot.hasError) {
                      return _SectionCard(
                        title: 'Tổng quan dữ liệu',
                        child: AppErrorState(
                          title: 'Không tải được thống kê',
                          message: _firstErrorMessage([
                            userSnapshot.error,
                            postSnapshot.error,
                            requestSnapshot.error,
                          ]),
                          compact: true,
                        ),
                      );
                    }

                    if (userSnapshot.connectionState == ConnectionState.waiting &&
                        postSnapshot.connectionState == ConnectionState.waiting &&
                        requestSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !userSnapshot.hasData &&
                        !postSnapshot.hasData &&
                        !requestSnapshot.hasData) {
                      return const _SectionCard(
                        title: 'Tổng quan dữ liệu',
                        child: AppLoadingState(
                          message: 'Đang tải thống kê hệ thống...',
                        ),
                      );
                    }

                    final users = userSnapshot.data ?? 0;
                    final posts = postSnapshot.data ?? 0;
                    final requests = requestSnapshot.data ?? 0;
                    final occupancy = users == 0
                        ? 0
                        : ((requests / math.max(users, 1)) * 100).round();

                    return Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: [
                        _OverviewCard(
                          title: 'Người dùng',
                          value: '$users',
                          subtitle: 'Thành viên đã đăng ký',
                          accent: const Color(0xFF0F766E),
                          icon: Icons.groups_rounded,
                        ),
                        _OverviewCard(
                          title: 'Bài đăng',
                          value: '$posts',
                          subtitle: 'Phòng đang hiển thị',
                          accent: const Color(0xFF2563EB),
                          icon: Icons.home_work_rounded,
                        ),
                        _OverviewCard(
                          title: 'Yêu cầu',
                          value: '$requests',
                          subtitle: 'Roommate request mới',
                          accent: const Color(0xFFF97316),
                          icon: Icons.mark_chat_unread_rounded,
                        ),
                        _OverviewCard(
                          title: 'Ty le tuong tac',
                          value: '$occupancy%',
                          subtitle: 'Request tren tong user',
                          accent: const Color(0xFF7C3AED),
                          icon: Icons.trending_up_rounded,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1100;

            if (!isWide) {
              return Column(
                children: [
                  _DashboardMainColumn(repository: repository),
                  const SizedBox(height: 18),
                  _DashboardSideColumn(repository: repository),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _DashboardMainColumn(repository: repository),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 2,
                  child: _DashboardSideColumn(repository: repository),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardMainColumn extends StatelessWidget {
  const _DashboardMainColumn({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<List<PostModel>>(
          stream: repository.getPostsStream(limit: 5),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _SectionCard(
                title: 'Bài đăng gần đây',
                trailing: const _TagPill(
                  label: 'Lỗi dữ liệu',
                  color: Color(0xFFFEE2E2),
                  textColor: Color(0xFFDC2626),
                ),
                child: AppErrorState(
                  title: 'Không tải được bài đăng',
                  message: _snapshotErrorText(snapshot.error),
                  compact: true,
                ),
              );
            }

            return _SectionCard(
              title: 'Bài đăng gần đây',
              trailing: const _TagPill(
                label: 'Dữ liệu thực',
                color: Color(0xFFE0F2FE),
                textColor: Color(0xFF0369A1),
              ),
              child: _PostsPreviewList(
                posts: snapshot.data ?? const [],
                isLoading:
                    snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData,
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        StreamBuilder<List<UserModel>>(
          stream: repository.getUsersStream(limit: 6),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _SectionCard(
                title: 'Thành viên mới',
                trailing: const _TagPill(
                  label: 'Lỗi dữ liệu',
                  color: Color(0xFFFEE2E2),
                  textColor: Color(0xFFDC2626),
                ),
                child: AppErrorState(
                  title: 'Không tải được người dùng',
                  message: _snapshotErrorText(snapshot.error),
                  compact: true,
                ),
              );
            }

            final users = (snapshot.data ?? const <UserModel>[])
                .where((user) => user.role != 'admin')
                .toList();
            return _SectionCard(
              title: 'Thành viên mới',
              trailing: const _TagPill(
                label: 'RoomMate',
                color: Color(0xFFDCFCE7),
                textColor: Color(0xFF15803D),
              ),
              child: _UsersPreviewGrid(
                users: users,
                isLoading:
                    snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DashboardSideColumn extends StatelessWidget {
  const _DashboardSideColumn({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<List<RoommateRequestModel>>(
          stream: repository.getRequestsStream(limit: 5),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _SectionCard(
                title: 'Yêu cầu gần đây',
                child: AppErrorState(
                  title: 'Không tải được yêu cầu',
                  message: _snapshotErrorText(snapshot.error),
                  compact: true,
                ),
              );
            }

            return _SectionCard(
              title: 'Yêu cầu gần đây',
              child: _RequestsPreviewList(
                requests: snapshot.data ?? const [],
                isLoading:
                    snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData,
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        const _SectionCard(
          title: 'Trong tam RoomMate',
          child: _InsightPromoCard(),
        ),
        const SizedBox(height: 18),
        const _SectionCard(
          title: 'Hoat dong tuan nay',
          child: _SimpleBarChartCard(),
        ),
      ],
    );
  }
}

class _UsersSection extends StatelessWidget {
  const _UsersSection({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: repository.getUsersStream(limit: 12),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SectionCard(
            title: 'Danh sách người dùng mới',
            child: AppErrorState(
              title: 'Không tải được danh sách người dùng',
              message: _snapshotErrorText(snapshot.error),
            ),
          );
        }

        final users = (snapshot.data ?? const <UserModel>[])
            .where((user) => user.role != 'admin')
            .toList();
        return _SectionCard(
          title: 'Danh sách người dùng mới',
          trailing: Text(
            '${users.length} thành viên',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: _UsersTable(
            users: users,
            isLoading: snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData,
          ),
        );
      },
    );
  }
}

class _PostsSection extends StatelessWidget {
  const _PostsSection({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: repository.getPostsStream(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SectionCard(
            title: 'Danh sách bài đăng',
            child: AppErrorState(
              title: 'Không tải được danh sách bài đăng',
              message: _snapshotErrorText(snapshot.error),
            ),
          );
        }

        return _SectionCard(
          title: 'Danh sách bài đăng',
          trailing: Text(
            '${snapshot.data?.length ?? 0} bài đăng',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: _PostsTable(
            posts: snapshot.data ?? const [],
            isLoading: snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData,
          ),
        );
      },
    );
  }
}

class _RequestsSection extends StatelessWidget {
  const _RequestsSection({required this.repository});

  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoommateRequestModel>>(
      stream: repository.getRequestsStream(limit: 10),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _SectionCard(
            title: 'Danh sách roommate request',
            child: AppErrorState(
              title: 'Không tải được roommate request',
              message: _snapshotErrorText(snapshot.error),
            ),
          );
        }

        return _SectionCard(
          title: 'Danh sách roommate request',
          trailing: Text(
            '${snapshot.data?.length ?? 0} yêu cầu',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: _RequestsTable(
            requests: snapshot.data ?? const [],
            isLoading: snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData,
          ),
        );
      },
    );
  }
}

class _RoomMateHeroCard extends StatelessWidget {
  const _RoomMateHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF164E63), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F766E),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản trị web RoomMate',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                
                
              ],
            ),
          ),
          Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạng thái hệ thống',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12),
                _HeroProgressItem(
                  label: 'Tương tác người dùng',
                  value: '84%',
                ),
                SizedBox(height: 10),
                _HeroProgressItem(
                  label: 'Độ phủ bài đăng',
                  value: '72%',
                ),
                SizedBox(height: 10),
                _HeroProgressItem(
                  label: 'Yêu cầu chờ xử lý',
                  value: '36%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroProgressItem extends StatelessWidget {
  const _HeroProgressItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (int.tryParse(value.replaceAll('%', '')) ?? 0) / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 112,
          child: Text(
            '$label  $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Icon(Icons.more_horiz_rounded, color: accent),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B0F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PostsPreviewList extends StatelessWidget {
  const _PostsPreviewList({
    required this.posts,
    required this.isLoading,
  });

  final List<PostModel> posts;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoadingState(
        message: 'Đang tải bài đăng...',
      );
    }

    if (posts.isEmpty) {
      return const _EmptyState(message: 'Chưa có bài đăng nào để hiển thị.');
    }

    return Column(
      children: posts
          .map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PostPreviewTile(post: post),
            ),
          )
          .toList(),
    );
  }
}

class _PostPreviewTile extends StatelessWidget {
  const _PostPreviewTile({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.bedroom_parent_rounded,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title.isEmpty ? 'Phòng mới' : post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _joinText([
                    post.location,
                    post.district,
                    post.province,
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _TagPill(
            label: _formatCurrency(post.price),
            color: const Color(0xFFE0F2FE),
            textColor: const Color(0xFF0369A1),
          ),
        ],
      ),
    );
  }
}

class _UsersPreviewGrid extends StatelessWidget {
  const _UsersPreviewGrid({
    required this.users,
    required this.isLoading,
  });

  final List<UserModel> users;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoadingState(
        message: 'Đang tải người dùng...',
      );
    }

    if (users.isEmpty) {
      return const _EmptyState(message: 'Chưa có người dùng mới.');
    }

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: users
          .map(
            (user) => SizedBox(
              width: 220,
              child: _UserProfileMiniCard(user: user),
            ),
          )
          .toList(),
    );
  }
}

class _UserProfileMiniCard extends StatelessWidget {
  const _UserProfileMiniCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFCCFBF1),
                backgroundImage:
                    user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                child: user.avatarUrl.isEmpty
                    ? Text(
                        _initials(user.fullName),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF115E59),
                        ),
                      )
                    : null,
              ),
              const Spacer(),
              _TagPill(
                label: user.role,
                color: user.role == 'admin'
                    ? const Color(0xFFF3E8FF)
                    : const Color(0xFFDCFCE7),
                textColor: user.role == 'admin'
                    ? const Color(0xFF7E22CE)
                    : const Color(0xFF15803D),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName.isEmpty ? 'Thành viên mới' : user.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.preferredLocation.isEmpty
                ? 'Chưa cập nhật khu vực'
                : user.preferredLocation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            user.occupation.isEmpty ? user.email : user.occupation,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsPreviewList extends StatelessWidget {
  const _RequestsPreviewList({
    required this.requests,
    required this.isLoading,
  });

  final List<RoommateRequestModel> requests;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoadingState(
        message: 'Đang tải yêu cầu...',
      );
    }

    if (requests.isEmpty) {
      return const _EmptyState(message: 'Chưa có roommate request mới.');
    }

    return Column(
      children: requests
          .map(
            (request) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequestPreviewTile(request: request),
            ),
          )
          .toList(),
    );
  }
}

class _RequestPreviewTile extends StatelessWidget {
  const _RequestPreviewTile({required this.request});

  final RoommateRequestModel request;

  @override
  Widget build(BuildContext context) {
    final status = _statusMeta(request.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: status.background,
            backgroundImage: request.requesterAvatar.isNotEmpty
                ? NetworkImage(request.requesterAvatar)
                : null,
            child: request.requesterAvatar.isEmpty
                ? Text(
                    _initials(request.requesterName),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: status.foreground,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requesterName.isEmpty
                      ? 'Yêu cầu mới'
                      : request.requesterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.message.isEmpty ? 'Không có nội dung.' : request.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _TagPill(
            label: status.label,
            color: status.background,
            textColor: status.foreground,
          ),
        ],
      ),
    );
  }
}

class _InsightPromoCard extends StatelessWidget {
  const _InsightPromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TagPill(
            label: 'RoomMate',
            color: Color(0x26FFFFFF),
            textColor: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'Kiểm soát chất lượng bài đăng và kết nối ghép phòng nhanh hơn.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Giao diện được tối ưu cho web để admin theo dõi dữ liệu hệ thống bằng các thẻ thống kê, danh sách và activity card.',
            style: TextStyle(
              color: Color(0xFFCCFBF1),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChartCard extends StatelessWidget {
  const _SimpleBarChartCard();

  @override
  Widget build(BuildContext context) {
    const values = [0.48, 0.72, 0.56, 0.84, 0.61, 0.77, 0.92];
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      children: [
        const Row(
          children: [
            Text(
              '84.5%',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F766E),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Tổng mức tương tác tuần này',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 140 * values[index],
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF67E8F9)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        labels[index],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.isLoading,
  });

  final List<UserModel> users;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoadingState(
        message: 'Đang tải danh sách người dùng...',
      );
    }

    if (users.isEmpty) {
      return const _EmptyState(message: 'Chưa có người dùng để hiển thị.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 32,
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        columns: const [
          DataColumn(label: Text('Người dùng')),
          DataColumn(label: Text('Khu vực')),
          DataColumn(label: Text('Nghề nghiệp')),
          DataColumn(label: Text('Vai trò')),
        ],
        rows: users
            .map(
              (user) => DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 240,
                      child: Text(
                        _joinText([user.fullName, user.email]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(_fallbackText(user.preferredLocation))),
                  DataCell(Text(_fallbackText(user.occupation))),
                  DataCell(Text(user.role)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PostsTable extends StatelessWidget {
  const _PostsTable({
    required this.posts,
    required this.isLoading,
  });

  final List<PostModel> posts;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoadingState(
        message: 'Đang tải danh sách bài đăng...',
      );
    }

    if (posts.isEmpty) {
      return const _EmptyState(message: 'Chưa có bài đăng để hiển thị.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        columns: const [
          DataColumn(label: Text('Tiêu đề')),
          DataColumn(label: Text('Khu vực')),
          DataColumn(label: Text('Loại phòng')),
          DataColumn(label: Text('Giá')),
          DataColumn(label: Text('Sức chứa')),
        ],
        rows: posts
            .map(
              (post) => DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 240,
                      child: Text(
                        _fallbackText(post.title),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 220,
                      child: Text(
                        _joinText([post.location, post.district, post.province]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(_fallbackText(post.roomType))),
                  DataCell(Text(_formatCurrency(post.price))),
                  DataCell(Text('${post.capacity}')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RequestsTable extends StatelessWidget {
  const _RequestsTable({
    required this.requests,
    required this.isLoading,
  });

  final List<RoommateRequestModel> requests;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppLoadingState(
        message: 'Đang tải roommate request...',
      );
    }

    if (requests.isEmpty) {
      return const _EmptyState(message: 'Chưa có roommate request để hiển thị.');
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        columns: const [
          DataColumn(label: Text('Người gửi')),
          DataColumn(label: Text('Post ID')),
          DataColumn(label: Text('Nội dung')),
          DataColumn(label: Text('Trạng thái')),
        ],
        rows: requests
            .map(
              (request) => DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 180,
                      child: Text(
                        _fallbackText(request.requesterName),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(_fallbackText(request.postId))),
                  DataCell(
                    SizedBox(
                      width: 320,
                      child: Text(
                        _fallbackText(request.message),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(_statusMeta(request.status).label),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Chưa có dữ liệu',
      message: message,
      compact: true,
      icon: Icons.inbox_outlined,
    );
  }
}

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.label,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String label;
  final IconData icon;
  final String title;
  final String description;
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

_StatusMeta _statusMeta(RoommateRequestStatus status) {
  switch (status) {
    case RoommateRequestStatus.accepted:
      return const _StatusMeta(
        label: 'Đã chấp nhận',
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF15803D),
      );
    case RoommateRequestStatus.rejected:
      return const _StatusMeta(
        label: 'Đã từ chối',
        background: Color(0xFFFEE2E2),
        foreground: Color(0xFFDC2626),
      );
    case RoommateRequestStatus.pending:
      return const _StatusMeta(
        label: 'Đang chờ',
        background: Color(0xFFFFEDD5),
        foreground: Color(0xFFEA580C),
      );
  }
}

String _formatCurrency(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i++) {
    final reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return '$buffer VND';
}

String _joinText(List<String> values) {
  final filtered = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  return filtered.isEmpty ? 'Đang cập nhật' : filtered.join(' • ');
}

String _fallbackText(String value) {
  return value.trim().isEmpty ? 'Đang cập nhật' : value.trim();
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) return 'RM';
  if (words.length == 1) {
    return words.first.substring(0, math.min(2, words.first.length)).toUpperCase();
  }

  return (words.first[0] + words.last[0]).toUpperCase();
}

String _snapshotErrorText(Object? error) {
  if (error == null) return 'Đã xảy ra lỗi khi tải dữ liệu.';
  return error.toString().replaceFirst('Exception: ', '');
}

String _firstErrorMessage(List<Object?> errors) {
  for (final error in errors) {
    if (error != null) return _snapshotErrorText(error);
  }
  return 'Đã xảy ra lỗi khi tải dữ liệu.';
}
