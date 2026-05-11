import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../room_group/data/models/room_group_model.dart';
import '../../data/models/expense_model.dart';
import '../viewmodels/expense_viewmodel.dart';
import 'add_expense_screen.dart';
import 'debt_screen.dart';
import 'expense_detail_screen.dart';

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
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Text(
          roomGroup.name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DebtScreen(
                  roomGroupId: roomGroup.id,
                  currentUserId: currentUserId,
                ),
              ),
            ),
            child: const Text(
              'Công nợ',
              style: TextStyle(
                color: AppColors.primary,
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
        icon: const Icon(Icons.add),
        label: const Text(
          'Thêm khoản chi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<ExpenseModel>>(
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
                title: 'Chưa có khoản chi nào',
                message:
                    'Nhấn "Thêm khoản chi" để ghi lại chi tiêu chung.',
                icon: Icons.receipt_long_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                return _ExpenseCard(
                  expense: expense,
                  currentUserId: currentUserId,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpenseDetailScreen(expense: expense),
                    ),
                  ),
                );
              },
            );
          },
        ),
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
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPayer ? 'Bạn đã trả' : 'Người khác trả',
                    style: TextStyle(
                      fontSize: 13,
                      color: isPayer
                          ? const Color(0xFF16A34A)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (expense.createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      ExpenseListScreen._formatDate(expense.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              ExpenseListScreen._formatMoney(expense.amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
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
