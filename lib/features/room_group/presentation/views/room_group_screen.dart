import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_state_widgets.dart';
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
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Chi tiêu',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Consumer<RoomGroupViewModel>(
          builder: (context, vm, _) => _buildBody(vm),
        ),
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
        onRetry:
            userId != null ? () => vm.loadUserRoomGroups(userId) : null,
      );
    }

    if (vm.roomGroups.isEmpty) {
      return const AppEmptyState(
        title: 'Chưa có nhóm phòng nào',
        message:
            'Khi bạn chấp nhận hoặc được chấp nhận yêu cầu ở ghép, nhóm phòng sẽ xuất hiện ở đây.',
        icon: Icons.group_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: vm.roomGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_outlined,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.memberIds.length} thành viên',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isActive ? 'Hoạt động' : group.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF16A34A)
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
