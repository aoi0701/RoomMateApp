import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../data/models/expense_share_model.dart';
import '../viewmodels/expense_viewmodel.dart';

class DebtScreen extends StatefulWidget {
  final String roomGroupId;
  final String currentUserId;

  const DebtScreen({
    super.key,
    required this.roomGroupId,
    required this.currentUserId,
  });

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ExpenseViewModel>().loadDebts(
            userId: widget.currentUserId,
            roomGroupId: widget.roomGroupId,
          );
    });
  }

  Future<void> _markAsPaid(ExpenseShareModel share) async {
    final vm = context.read<ExpenseViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await vm.markAsPaid(share.id);
    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã đánh dấu thanh toán'
              : (vm.errorMessage ?? 'Cập nhật thất bại'),
        ),
      ),
    );

    if (success) {
      vm.loadDebts(
        userId: widget.currentUserId,
        roomGroupId: widget.roomGroupId,
      );
    }
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
          'Công nợ',
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
            if (vm.isLoading) {
              return const AppLoadingState(message: 'Đang tải công nợ...');
            }

            if (vm.errorMessage != null) {
              return AppErrorState(
                title: 'Không tải được công nợ',
                message: vm.errorMessage!,
                onRetry: () => vm.loadDebts(
                  userId: widget.currentUserId,
                  roomGroupId: widget.roomGroupId,
                ),
              );
            }

            final hasNoData =
                vm.myDebts.isEmpty && vm.othersDebts.isEmpty;

            if (hasNoData) {
              return const AppEmptyState(
                title: 'Không có công nợ',
                message: 'Tất cả khoản chi đã được thanh toán.',
                icon: Icons.check_circle_outline,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (vm.myDebts.isNotEmpty) ...[
                  _buildSectionTitle('Tôi nợ'),
                  const SizedBox(height: 12),
                  ...vm.myDebts.map(
                    (share) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DebtCard(
                        share: share,
                        formatMoney: _formatMoney,
                        canPay: true,
                        onMarkAsPaid: () => _markAsPaid(share),
                        isActionLoading: vm.isLoading,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (vm.othersDebts.isNotEmpty) ...[
                  _buildSectionTitle('Người khác nợ tôi'),
                  const SizedBox(height: 12),
                  ...vm.othersDebts.map(
                    (share) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DebtCard(
                        share: share,
                        formatMoney: _formatMoney,
                        canPay: false,
                        onMarkAsPaid: null,
                        isActionLoading: false,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final ExpenseShareModel share;
  final String Function(double) formatMoney;
  final bool canPay;
  final VoidCallback? onMarkAsPaid;
  final bool isActionLoading;

  const _DebtCard({
    required this.share,
    required this.formatMoney,
    required this.canPay,
    required this.onMarkAsPaid,
    required this.isActionLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _UserName(userId: share.fromUserId),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    _UserName(userId: share.toUserId),
                  ],
                ),
              ),
              Text(
                formatMoney(share.amountOwed),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (canPay && onMarkAsPaid != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isActionLoading ? null : onMarkAsPaid,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Đánh dấu đã trả',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
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
