import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/app_button.dart';
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

  Future<void> _settleAll(NetDebtEntry entry) async {
    final vm = context.read<ExpenseViewModel>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thanh toán tất cả'),
        content: const Text(
          'Bạn có chắc muốn đánh dấu tất cả công nợ này là đã thanh toán?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Xác nhận',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await vm.settleAllDebts(
      fromUserId: entry.fromUserId,
      toUserId: entry.toUserId,
      roomGroupId: widget.roomGroupId,
    );
    if (!mounted) return;
    if (success) {
      vm.loadNetDebtSummary(
        roomGroupId: widget.roomGroupId,
        currentUserId: widget.currentUserId,
      );
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

          if (vm.myDebts.isEmpty &&
              vm.othersDebts.isEmpty &&
              vm.netDebts.isEmpty) {
            return const AppEmptyState(
              title: 'Không có công nợ',
              message: 'Tất cả khoản chi đã được thanh toán.',
              icon: Icons.check_circle_outline_rounded,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Net debt section
              if (vm.netDebts.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Sau khi đối soát',
                  count: vm.netDebts.length,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                ...vm.netDebts.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NetDebtCard(
                      entry: entry,
                      currentUserId: widget.currentUserId,
                      formatMoney: FormatUtils.formatMoney,
                      onSettle: () => _settleAll(entry),
                      isLoading: vm.isLoading,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
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

class _NetDebtCard extends StatelessWidget {
  final NetDebtEntry entry;
  final String currentUserId;
  final String Function(double) formatMoney;
  final VoidCallback onSettle;
  final bool isLoading;

  const _NetDebtCard({
    required this.entry,
    required this.currentUserId,
    required this.formatMoney,
    required this.onSettle,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDebtor = entry.fromUserId == currentUserId;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDebtor
                          ? 'Bạn cần trả'
                          : 'Bạn được nhận từ',
                      style: AppTextStyles.caption.copyWith(
                        color: isDebtor
                            ? AppColors.danger
                            : AppColors.successText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _UserNameText(
                          userId: isDebtor ? entry.toUserId : entry.fromUserId,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatMoney(entry.netAmount),
                          style: AppTextStyles.labelLg.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isDebtor) ...[
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: 'Thanh toán tất cả',
              onTap: isLoading ? null : onSettle,
              isLoading: isLoading,
              height: 42,
            ),
          ],
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _UserNameText(userId: share.fromUserId),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: _UserNameText(userId: share.toUserId),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    formatMoney(share.amountOwed),
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
          if (canPay && onMarkAsPaid != null) ...[
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: 'Đánh dấu đã trả',
              onTap: isActionLoading ? null : onMarkAsPaid,
              isLoading: isActionLoading,
              height: 42,
            ),
          ],
        ],
      ),
    );
  }
}

class _UserNameText extends StatelessWidget {
  final String userId;
  const _UserNameText({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: context.read<UserProfileViewModel>().getUserProfileStream(userId),
      builder: (context, snapshot) {
        String name = 'Người dùng';
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!.data()?['fullName'] ?? 'Người dùng';
        }
        return Text(
          name,
          style: AppTextStyles.label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      },
    );
  }
}

