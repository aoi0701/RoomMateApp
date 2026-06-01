import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/user_name_widgets.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../room_group/data/models/room_group_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/expense_share_model.dart';
import '../viewmodels/expense_viewmodel.dart';
import 'expense_form_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseModel expense;
  final RoomGroupModel roomGroup;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.roomGroup,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late ExpenseModel _expense;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ExpenseViewModel>().loadExpenseShares(
        expenseId: _expense.id,
        roomGroupId: _expense.roomGroupId,
      );
    });
  }

  Future<void> _reloadExpense() async {
    final updated = await context.read<ExpenseViewModel>().getExpenseById(
      _expense.id,
    );
    if (updated != null && mounted) {
      setState(() => _expense = updated);
    }
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khoản chi'),
        content: const Text('Bạn có chắc muốn xóa khoản chi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final vm = context.read<ExpenseViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final success = await vm.deleteExpense(
                expenseId: widget.expense.id,
                roomGroupId: widget.expense.roomGroupId,
              );
              if (!mounted) return;
              if (success) {
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Đã xóa khoản chi')),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(vm.errorMessage ?? 'Xóa thất bại')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthViewModel>().user?.uid ?? '';
    final isMember =
        currentUserId.isNotEmpty &&
        widget.roomGroup.memberIds.contains(currentUserId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết khoản chi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isMember) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final vm = context.read<ExpenseViewModel>();
                final messenger = ScaffoldMessenger.of(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseFormScreen(
                      expense: _expense,
                      roomGroup: widget.roomGroup,
                    ),
                  ),
                );
                if (!mounted) return;
                if (result == true) {
                  await _reloadExpense();
                  if (!mounted) return;
                  vm.loadExpenseShares(
                    expenseId: _expense.id,
                    roomGroupId: _expense.roomGroupId,
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật khoản chi')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.danger,
              onPressed: _showDeleteDialog,
            ),
          ],
        ],
      ),
      body: Consumer<ExpenseViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(_expense),
                const SizedBox(height: 20),
                _buildSharesSection(vm, currentUserId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(ExpenseModel expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x305B6AF0),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Tổng chi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            FormatUtils.formatMoney(expense.amount),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            expense.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          _buildMetaRow(
            icon: Icons.person_outline_rounded,
            label: 'Người trả',
            child: UserNameText(userId: expense.paidBy),
          ),
          const SizedBox(height: 12),
          _buildMetaRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ngày tạo',
            child: Text(
              _formatDate(expense.createdAt),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (expense.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMetaRow(
              icon: Icons.notes_rounded,
              label: 'Ghi chú',
              child: Text(
                expense.note,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildSharesSection(ExpenseViewModel vm, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phân chia chi phí', style: AppTextStyles.h2),
        const SizedBox(height: 16),
        if (vm.isLoading)
          const AppLoadingState(message: 'Đang tải...')
        else if (vm.errorMessage != null)
          AppErrorState(
            title: 'Lỗi',
            message: vm.errorMessage!,
            compact: true,
            onRetry: () => vm.loadExpenseShares(
              expenseId: widget.expense.id,
              roomGroupId: widget.expense.roomGroupId,
            ),
          )
        else if (vm.shares.isEmpty)
          const AppEmptyState(
            title: 'Không có phân chia',
            message: 'Khoản chi này không có ai cần thanh toán lại.',
            compact: true,
            icon: Icons.check_circle_outline_rounded,
          )
        else ...[
          ...vm.shares
              .where((s) => !s.isArchived)
              .map(
                (share) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ShareCard(share: share),
                ),
              ),
          if (vm.shares.any((s) => s.isArchived)) ...[
            const SizedBox(height: 8),
            Text('Lịch sử chỉnh sửa', style: AppTextStyles.label),
            const SizedBox(height: 8),
            ...vm.shares
                .where((s) => s.isArchived)
                .map(
                  (share) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShareCard(share: share, isEdited: true),
                  ),
                ),
          ],
        ],
      ],
    );
  }
}

class _ShareCard extends StatelessWidget {
  final ExpenseShareModel share;
  final bool isEdited;

  const _ShareCard({required this.share, this.isEdited = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEdited ? 0.55 : 1.0,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creditor
                  _RoleChip(
                    label: 'Người nhận',
                    textColor: AppColors.successText,
                    bgColor: AppColors.successSurface,
                  ),
                  const SizedBox(height: 8),
                  UserNameTile(userId: share.toUserId, avatarSize: 32),
                  const SizedBox(height: 12),
                  // Debtor
                  _RoleChip(
                    label: 'Người nợ',
                    textColor: AppColors.dangerText,
                    bgColor: AppColors.dangerSurface,
                  ),
                  const SizedBox(height: 8),
                  UserNameTile(userId: share.fromUserId, avatarSize: 32),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    FormatUtils.formatMoney(share.amountOwed),
                    style: AppTextStyles.h3.copyWith(
                      color: isEdited
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      decoration: isEdited ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (isEdited)
                    StatusBadge(
                      label: 'Đã chỉnh sửa',
                      type: BadgeType.info,
                      icon: Icons.edit_outlined,
                    )
                  else
                    StatusBadge(
                      label: share.isPaid ? 'Đã trả' : 'Chưa trả',
                      type: share.isPaid
                          ? BadgeType.success
                          : BadgeType.warning,
                      icon: share.isPaid
                          ? Icons.check_circle_outline_rounded
                          : Icons.schedule_rounded,
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

class _RoleChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const _RoleChip({
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
