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

  Future<void> _confirmDisband(
      RoomGroupViewModel vm, RoomGroupModel group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Giải tán nhóm'),
        content: Text(
          'Bạn có chắc muốn giải tán nhóm "${group.name}"?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Giải tán',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await vm.disbandGroup(group.id);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Không thể giải tán nhóm'),
        ),
      );
    }
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
    final currentUserId = context.read<AuthViewModel>().user?.uid;

    if (vm.isLoading) {
      return const AppLoadingState(message: 'Đang tải nhóm phòng...');
    }

    if (vm.errorMessage != null) {
      return AppErrorState(
        title: 'Không tải được dữ liệu',
        message: vm.errorMessage!,
        onRetry: currentUserId != null
            ? () => vm.loadUserRoomGroups(currentUserId)
            : null,
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
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = vm.roomGroups[index];
        final isDisbanded = group.status == 'disbanded';
        return _RoomGroupCard(
          group: group,
          onTap: isDisbanded ? null : () => _openExpenseList(group),
          onDisband: (!isDisbanded && group.ownerId == currentUserId)
              ? () => _confirmDisband(vm, group)
              : null,
        );
      },
    );
  }
}

class _RoomGroupCard extends StatelessWidget {
  final RoomGroupModel group;
  final VoidCallback? onTap;
  final VoidCallback? onDisband;

  const _RoomGroupCard({
    required this.group,
    required this.onTap,
    this.onDisband,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = group.status == 'active';
    final isDisbanded = group.status == 'disbanded';

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
                gradient: LinearGradient(
                  colors: isDisbanded
                      ? [AppColors.textSecondary, AppColors.textSecondary]
                      : [AppColors.primary, AppColors.primaryDark],
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
              label: isActive
                  ? 'Hoạt động'
                  : (isDisbanded ? 'Đã giải tán' : group.status),
              type: isActive ? BadgeType.success : BadgeType.neutral,
              icon: isActive ? Icons.circle : null,
            ),
            if (onDisband != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.group_off_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                onPressed: onDisband,
                tooltip: 'Giải tán nhóm',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ] else if (!isDisbanded) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
