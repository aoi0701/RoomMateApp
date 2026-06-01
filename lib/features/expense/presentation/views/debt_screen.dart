import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/user_name_widgets.dart';
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
      final vm = context.read<ExpenseViewModel>();
      vm.loadDebtScreenData(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Công nợ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ExpenseViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const AppLoadingState(message: 'Đang tải công nợ...');
          }

          if (vm.errorMessage != null) {
            return AppErrorState(
              title: 'Không tải được công nợ',
              message: vm.errorMessage!,
              onRetry: () => vm.loadDebtScreenData(
                userId: widget.currentUserId,
                roomGroupId: widget.roomGroupId,
              ),
            );
          }

          if (vm.myDebts.isEmpty && vm.othersDebts.isEmpty) {
            return const AppEmptyState(
              title: 'Không có công nợ',
              message: 'Tất cả khoản chi đã được thanh toán.',
              icon: Icons.check_circle_outline_rounded,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (vm.myDebts.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Tôi nợ',
                  count: vm.myDebts.length,
                  color: AppColors.danger,
                ),
                const SizedBox(height: 12),
                ...vm.myDebts.map(
                  (share) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DebtCard(
                      share: share,
                      formatMoney: FormatUtils.formatMoney,
                      canPay: true,
                      onMarkAsPaid: () => _markAsPaid(share),
                      isActionLoading: vm.isLoading,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (vm.othersDebts.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Người khác nợ tôi',
                  count: vm.othersDebts.length,
                  color: AppColors.success,
                ),
                const SizedBox(height: 12),
                ...vm.othersDebts.map(
                  (share) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DebtCard(
                      share: share,
                      formatMoney: FormatUtils.formatMoney,
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.h3),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
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
    // canPay=true → "Tôi nợ": show creditor (toUserId)
    // canPay=false → "Người khác nợ tôi": show debtor (fromUserId)
    final relevantUserId = canPay ? share.toUserId : share.fromUserId;
    final accentColor = canPay ? AppColors.dangerText : AppColors.successText;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                // Name — Expanded prevents overflow
                Expanded(
                  child: UserNameText(
                    userId: relevantUserId,
                    style: AppTextStyles.label,
                  ),
                ),
                const SizedBox(width: 12),
                // Amount + status stacked
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoney(share.amountOwed),
                      style: AppTextStyles.h3.copyWith(color: accentColor),
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(
                      label: share.isPaid ? 'Đã trả' : 'Chưa trả',
                      type: share.isPaid ? BadgeType.success : BadgeType.warning,
                      icon: share.isPaid
                          ? Icons.check_circle_outline_rounded
                          : Icons.schedule_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canPay && onMarkAsPaid != null) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: AppPrimaryButton(
                label: 'Đánh dấu đã trả',
                onTap: isActionLoading ? null : onMarkAsPaid,
                isLoading: isActionLoading,
                height: 42,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

