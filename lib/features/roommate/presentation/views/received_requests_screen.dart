import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../data/models/roommate_request_model.dart';
import '../viewmodels/roommate_request_viewmodel.dart';

// Màn hình yêu cầu đã nhận: realtime stream, chấp nhận → tạo nhóm phòng, từ chối/xóa
class ReceivedRequestsScreen extends StatefulWidget {
  const ReceivedRequestsScreen({super.key});

  @override
  State<ReceivedRequestsScreen> createState() => _ReceivedRequestsScreenState();
}

class _ReceivedRequestsScreenState extends State<ReceivedRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RoommateRequestViewModel>().ensureReceivedRequestsListening();
    });
  }

  Future<void> _acceptRequest(String requestId) async {
    final viewModel = context.read<RoommateRequestViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await viewModel.acceptRequest(requestId);

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã chấp nhận yêu cầu'
              : (viewModel.errorMessage ?? 'Chấp nhận yêu cầu thất bại'),
        ),
      ),
    );
  }

  Future<void> _rejectRequest(String requestId) async {
    final viewModel = context.read<RoommateRequestViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await viewModel.rejectRequest(requestId);

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Đã từ chối yêu cầu'
              : (viewModel.errorMessage ?? 'Từ chối yêu cầu thất bại'),
        ),
      ),
    );
  }

  Color _statusColor(RoommateRequestStatus status) {
    switch (status) {
      case RoommateRequestStatus.accepted:
        return AppColors.success;
      case RoommateRequestStatus.rejected:
        return AppColors.danger;
      case RoommateRequestStatus.pending:
        return AppColors.warning;
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
    return Consumer<RoommateRequestViewModel>(
      builder: (context, viewModel, _) {
        final requests = viewModel.receivedRequests;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Yêu cầu đã nhận'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: viewModel.isReceivedRequestsLoading
                ? const AppLoadingState(message: 'Đang tải danh sách yêu cầu...')
                : viewModel.errorMessage != null
                    ? AppErrorState(
                        title: 'Không tải được yêu cầu',
                        message: viewModel.errorMessage!,
                        onRetry: viewModel.ensureReceivedRequestsListening,
                      )
                    : requests.isEmpty
                        ? const AppEmptyState(
                            title: 'Chưa có yêu cầu nào',
                            message:
                                'Các yêu cầu ở ghép gửi đến bạn sẽ hiển thị ở đây.',
                            icon: Icons.inbox_outlined,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: requests.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final request = requests[index];
                              final statusColor = _statusColor(request.status);
                              final statusText = _statusText(request.status);

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
                                    if (request.inviteType ==
                                        RoommateInviteType.profileInvite)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primarySurface,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.person_add_alt_1_outlined,
                                                size: 13,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Lời mời kết bạn',
                                                style: AppTextStyles.labelSm
                                                    .copyWith(
                                                        color:
                                                            AppColors.primary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    Row(
                                      children: [
                                        AppAvatar(
                                          name: request.requesterName.isNotEmpty
                                              ? request.requesterName
                                              : 'Người dùng',
                                          avatarUrl: request.requesterAvatar.isNotEmpty
                                              ? request.requesterAvatar
                                              : null,
                                          size: 48,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                request.requesterName.isNotEmpty
                                                    ? request.requesterName
                                                    : 'Người dùng',
                                                style: AppTextStyles.labelLg,
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  statusText,
                                                  style: AppTextStyles.labelSm
                                                      .copyWith(
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.inputFill,
                                        borderRadius: BorderRadius.circular(16),
                                        border:
                                            Border.all(color: AppColors.inputBorder),
                                      ),
                                      child: Text(
                                        request.message.isNotEmpty
                                            ? request.message
                                            : 'Không có lời nhắn',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                    if (request.status ==
                                        RoommateRequestStatus.pending) ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: viewModel.isLoading
                                                  ? null
                                                  : () =>
                                                      _rejectRequest(request.id),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.danger,
                                                side: const BorderSide(
                                                  color: AppColors.danger,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                              ),
                                              child: Text(
                                                'Từ chối',
                                                style: AppTextStyles.buttonSm
                                                    .copyWith(
                                                  color: AppColors.danger,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: AppPrimaryButton(
                                              label: 'Chấp nhận',
                                              isLoading: viewModel.isLoading,
                                              onTap: viewModel.isLoading
                                                  ? null
                                                  : () =>
                                                      _acceptRequest(request.id),
                                              height: 48,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        );
      },
    );
  }
}
