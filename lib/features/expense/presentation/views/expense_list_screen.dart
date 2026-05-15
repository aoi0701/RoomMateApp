import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../room_group/data/models/room_group_model.dart';
import '../../data/models/expense_model.dart';
import '../viewmodels/expense_viewmodel.dart';
import 'add_expense_screen.dart';
import 'debt_screen.dart';
import 'expense_detail_screen.dart';
import 'monthly_summary_screen.dart';

class ExpenseListScreen extends StatelessWidget {
  final RoomGroupModel roomGroup;

  const ExpenseListScreen({super.key, required this.roomGroup});

  static String _formatMoney(double amount) {
    final text = amount.toStringAsFixed(0);
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
    return '${buffer.toString().split('').reversed.join()}đ';
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthViewModel>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(roomGroup.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MonthlySummaryScreen(roomGroup: roomGroup),
              ),
            ),
            icon: const Icon(Icons.bar_chart_rounded, size: 16),
            label: const Text('Thống kê'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DebtScreen(
                  roomGroupId: roomGroup.id,
                  currentUserId: currentUserId,
                ),
              ),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: const Text('Công nợ'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddExpenseScreen(roomGroup: roomGroup),
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Thêm khoản chi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: context
            .read<ExpenseViewModel>()
            .getExpensesStream(roomGroup.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Đang tải khoản chi...');
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Không tải được dữ liệu',
              message: '${snapshot.error}',
            );
          }

          final expenses = snapshot.data ?? [];

          if (expenses.isEmpty) {
            return const AppEmptyState(
              title: 'Chưa có khoản chi',
              message: 'Nhấn "Thêm khoản chi" để ghi lại chi tiêu chung.',
              icon: Icons.receipt_long_outlined,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: expenses.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _ExpenseCard(
                expense: expense,
                currentUserId: currentUserId,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseDetailScreen(
                      expense: expense,
                      roomGroup: roomGroup,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String currentUserId;
  final VoidCallback onTap;

  const _ExpenseCard({
    required this.expense,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPayer = expense.paidBy == currentUserId;

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: AppTextStyles.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isPayer
                              ? AppColors.success
                              : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isPayer ? 'Bạn đã trả' : 'Người khác trả',
                        style: AppTextStyles.caption.copyWith(
                          color: isPayer
                              ? AppColors.successText
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (expense.createdAt != null) ...[
                        const SizedBox(width: 8),
                        Text('·', style: AppTextStyles.caption),
                        const SizedBox(width: 8),
                        Text(
                          ExpenseListScreen._formatDate(expense.createdAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        ExpenseListScreen._formatMoney(expense.amount),
                        style: AppTextStyles.labelLg.copyWith(
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
