import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/expense_share_model.dart';
import '../viewmodels/expense_viewmodel.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final ExpenseModel expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ExpenseViewModel>().loadExpenseShares(
        expenseId: widget.expense.id,
        roomGroupId: widget.expense.roomGroupId,
      );
    });
  }

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
    final expense = widget.expense;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Chi tiết khoản chi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Consumer<ExpenseViewModel>(
          builder: (context, vm, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(expense),
                  const SizedBox(height: 16),
                  _buildSharesSection(vm, currentUserId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(ExpenseModel expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expense.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatMoney(expense.amount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          _buildInfoRow(
            label: 'Người trả',
            child: _UserName(userId: expense.paidBy),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            label: 'Ngày tạo',
            child: Text(
              _formatDate(expense.createdAt),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (expense.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
              label: 'Ghi chú',
              child: Text(
                expense.note,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
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
        const Text(
          'Phân chia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
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
            message: 'Người trả không cần nợ chính họ.',
            compact: true,
            icon: Icons.check_circle_outline,
          )
        else
          ...vm.shares.map(
            (share) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShareCard(
                share: share,
                currentUserId: currentUserId,
              ),
            ),
          ),
      ],
    );
  }
}

class _ShareCard extends StatelessWidget {
  final ExpenseShareModel share;
  final String currentUserId;

  const _ShareCard({required this.share, required this.currentUserId});

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _UserName(userId: share.fromUserId),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    _UserName(userId: share.toUserId),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMoney(share.amountOwed),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: share.isPaid
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              share.isPaid ? 'Đã trả' : 'Chưa trả',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: share.isPaid
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserName extends StatelessWidget {
  final String userId;

  const _UserName({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: context
          .read<UserProfileViewModel>()
          .getUserProfileStream(userId),
      builder: (context, snapshot) {
        String name = 'Người dùng';
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!.data()?['fullName'] ?? 'Người dùng';
        }
        return Text(
          name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        );
      },
    );
  }
}
