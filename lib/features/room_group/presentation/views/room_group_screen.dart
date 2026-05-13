import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../expense/presentation/views/expense_list_screen.dart';
import '../../data/models/room_group_model.dart';
import '../viewmodels/room_group_viewmodel.dart';

class RoomGroupScreen extends StatefulWidget {
  const RoomGroupScreen({super.key});

  @override
  State<RoomGroupScreen> createState() => _RoomGroupScreenState();
}

class _RoomGroupScreenState extends State<RoomGroupScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthViewModel>().user?.uid;
      if (userId != null) {
        context.read<RoomGroupViewModel>().loadUserRoomGroups(userId);
      }
    });
  }

  void _openExpenseList(RoomGroupModel group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExpenseListScreen(roomGroup: group)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiêu nhóm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<RoomGroupViewModel>(
        builder: (context, vm, _) => _buildBody(vm),
      ),
    );
  }

  Widget _buildBody(RoomGroupViewModel vm) {
    if (vm.isLoading) {
      return const AppLoadingState(message: 'Đang tải nhóm phòng...');
    }

    if (vm.errorMessage != null) {
      final userId = context.read<AuthViewModel>().user?.uid;
      return AppErrorState(
        title: 'Không tải được dữ liệu',
        message: vm.errorMessage!,
        onRetry: userId != null ? () => vm.loadUserRoomGroups(userId) : null,
      );
    }

    if (vm.roomGroups.isEmpty) {
      return const AppEmptyState(
        title: 'Chưa có nhóm phòng',
        message:
            'Khi bạn chấp nhận hoặc được chấp nhận yêu cầu ở ghép, nhóm phòng sẽ xuất hiện ở đây.',
        icon: Icons.group_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: vm.roomGroups.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = vm.roomGroups[index];
        return _RoomGroupCard(
          group: group,
          onTap: () => _openExpenseList(group),
        );
      },
    );
  }
}

class _RoomGroupCard extends StatelessWidget {
  final RoomGroupModel group;
  final VoidCallback onTap;

  const _RoomGroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = group.status == 'active';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.group_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: AppTextStyles.labelLg),
                  const SizedBox(height: 3),
                  Text(
                    '${group.memberIds.length} thành viên',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: isActive ? 'Hoạt động' : group.status,
              type: isActive ? BadgeType.success : BadgeType.neutral,
              icon: isActive ? Icons.circle : null,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
