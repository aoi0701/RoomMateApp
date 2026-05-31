import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../roommate/data/models/roommate_request_model.dart';
import '../../../roommate/presentation/viewmodels/roommate_request_viewmodel.dart';

class SentInvitesScreen extends StatelessWidget {
  const SentInvitesScreen({super.key});

  Color _statusColor(RoommateRequestStatus status) {
    switch (status) {
      case RoommateRequestStatus.accepted:
        return AppColors.successText;
      case RoommateRequestStatus.rejected:
        return AppColors.dangerText;
      case RoommateRequestStatus.pending:
        return AppColors.warningText;
    }
  }

  Color _statusSurface(RoommateRequestStatus status) {
    switch (status) {
      case RoommateRequestStatus.accepted:
        return AppColors.successSurface;
      case RoommateRequestStatus.rejected:
        return AppColors.dangerSurface;
      case RoommateRequestStatus.pending:
        return AppColors.warningSurface;
    }
  }

  String _statusText(RoommateRequestStatus status) {
    switch (status) {
      case RoommateRequestStatus.accepted:
        return 'Đã chấp nhận';
      case RoommateRequestStatus.rejected:
        return 'Đã từ chối';
      case RoommateRequestStatus.pending:
        return 'Đang chờ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<RoommateRequestViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lời mời đã gửi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<RoommateRequestModel>>(
          stream: vm.sentProfileInvitesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoadingState(
                  message: 'Đang tải danh sách lời mời...');
            }

            if (snapshot.hasError) {
              return AppErrorState(
                title: 'Không tải được danh sách',
                message: '${snapshot.error}',
              );
            }

            final invites =
                snapshot.data ?? const <RoommateRequestModel>[];

            if (invites.isEmpty) {
              return const AppEmptyState(
                icon: Icons.send_outlined,
                title: 'Chưa gửi lời mời nào',
                message: 'Các lời mời ở ghép bạn đã gửi sẽ hiển thị ở đây.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: invites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final invite = invites[index];
                return _SentInviteCard(
                  invite: invite,
                  statusText: _statusText(invite.status),
                  statusColor: _statusColor(invite.status),
                  statusSurface: _statusSurface(invite.status),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SentInviteCard extends StatelessWidget {
  final RoommateRequestModel invite;
  final String statusText;
  final Color statusColor;
  final Color statusSurface;

  const _SentInviteCard({
    required this.invite,
    required this.statusText,
    required this.statusColor,
    required this.statusSurface,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        invite.targetName.isNotEmpty ? invite.targetName : 'Người dùng';
    final avatar =
        invite.targetAvatar.isNotEmpty ? invite.targetAvatar : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
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
              AppAvatar(name: name, avatarUrl: avatar, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.labelLg),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusSurface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusText,
                        style: AppTextStyles.labelSm
                            .copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (invite.createdAt != null)
                Text(
                  _formatDate(invite.createdAt!),
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          if (invite.message.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Text(
                invite.message,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes} phút trước';
      return '${diff.inHours} giờ trước';
    }
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${date.day}/${date.month}/${date.year}';
  }
}
