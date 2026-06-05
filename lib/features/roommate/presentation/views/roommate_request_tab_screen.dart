import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../data/models/roommate_request_model.dart';
import '../viewmodels/roommate_request_viewmodel.dart';

// Màn hình tab yêu cầu ghép phòng: tab "Đã nhận" và tab "Đã gửi"
class RoommateRequestTabScreen extends StatefulWidget {
  const RoommateRequestTabScreen({super.key});

  @override
  State<RoommateRequestTabScreen> createState() =>
      _RoommateRequestTabScreenState();
}

class _RoommateRequestTabScreenState extends State<RoommateRequestTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<RoommateRequestViewModel>();
      vm.ensureReceivedRequestsListening();
      vm.ensureSentRequestsListening();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoommateRequestViewModel>(
      builder: (context, vm, _) {
        final pendingCount = vm.pendingCount;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Yêu cầu ở ghép'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelStyle: AppTextStyles.labelLg,
              unselectedLabelStyle: AppTextStyles.body,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Đã nhận'),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(text: 'Đã gửi'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _ReceivedTab(vm: vm),
              _SentTab(vm: vm),
            ],
          ),
        );
      },
    );
  }
}

// ── Received tab ──────────────────────────────────────────────────────────────

class _ReceivedTab extends StatefulWidget {
  final RoommateRequestViewModel vm;
  const _ReceivedTab({required this.vm});

  @override
  State<_ReceivedTab> createState() => _ReceivedTabState();
}

class _ReceivedTabState extends State<_ReceivedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _acceptRequest(String requestId) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await widget.vm.acceptRequest(requestId);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(success
          ? 'Đã chấp nhận yêu cầu'
          : (widget.vm.errorMessage ?? 'Chấp nhận yêu cầu thất bại')),
    ));
  }

  Future<void> _rejectRequest(String requestId) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await widget.vm.rejectRequest(requestId);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(success
          ? 'Đã từ chối yêu cầu'
          : (widget.vm.errorMessage ?? 'Từ chối yêu cầu thất bại')),
    ));
  }

  Future<void> _deleteRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa yêu cầu'),
        content: const Text('Bạn có chắc muốn xóa yêu cầu này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Hủy',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Xóa',
              style: AppTextStyles.label.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await widget.vm.deleteRequest(requestId);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(success
          ? 'Đã xóa yêu cầu'
          : (widget.vm.errorMessage ?? 'Xóa yêu cầu thất bại')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm = widget.vm;

    if (vm.isReceivedRequestsLoading) {
      return const AppLoadingState(message: 'Đang tải danh sách yêu cầu...');
    }

    if (vm.errorMessage != null && vm.receivedRequests.isEmpty) {
      return AppErrorState(
        title: 'Không tải được yêu cầu',
        message: vm.errorMessage!,
        onRetry: vm.ensureReceivedRequestsListening,
      );
    }

    if (vm.receivedRequests.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Chưa có yêu cầu nào',
        message: 'Các yêu cầu ở ghép gửi đến bạn sẽ hiển thị ở đây.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: vm.receivedRequests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final request = vm.receivedRequests[index];
        return _ReceivedRequestCard(
          request: request,
          isLoading: vm.isLoading,
          onAccept: () => _acceptRequest(request.id),
          onReject: () => _rejectRequest(request.id),
          onDelete: request.status == RoommateRequestStatus.rejected
              ? () => _deleteRequest(request.id)
              : null,
        );
      },
    );
  }
}

class _ReceivedRequestCard extends StatelessWidget {
  final RoommateRequestModel request;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onDelete;

  const _ReceivedRequestCard({
    required this.request,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
    this.onDelete,
  });

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
    final name = request.requesterName.isNotEmpty
        ? request.requesterName
        : 'Người dùng';
    final avatar =
        request.requesterAvatar.isNotEmpty ? request.requesterAvatar : null;
    final statusColor = _statusColor(request.status);

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
          if (request.inviteType == RoommateInviteType.profileInvite)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_add_alt_1_outlined,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Lời mời kết bạn',
                      style: AppTextStyles.labelSm
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
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
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusText(request.status),
                        style:
                            AppTextStyles.labelSm.copyWith(color: statusColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: isLoading ? null : onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger, size: 20),
                  tooltip: 'Xóa yêu cầu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
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
              request.message.isNotEmpty
                  ? request.message
                  : 'Không có lời nhắn',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          if (request.status == RoommateRequestStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Từ chối',
                      style: AppTextStyles.buttonSm
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Chấp nhận',
                    isLoading: isLoading,
                    onTap: isLoading ? null : onAccept,
                    height: 48,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sent tab ──────────────────────────────────────────────────────────────────

class _SentTab extends StatefulWidget {
  final RoommateRequestViewModel vm;
  const _SentTab({required this.vm});

  @override
  State<_SentTab> createState() => _SentTabState();
}

class _SentTabState extends State<_SentTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _deleteRequest(String requestId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy lời mời'),
        content: const Text('Bạn có chắc muốn hủy lời mời này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Không',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Hủy lời mời',
              style: AppTextStyles.label.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await widget.vm.deleteRequest(requestId);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(success
          ? 'Đã hủy lời mời'
          : (widget.vm.errorMessage ?? 'Hủy lời mời thất bại')),
    ));
  }

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm = widget.vm;

    if (vm.isSentRequestsLoading) {
      return const AppLoadingState(message: 'Đang tải danh sách lời mời...');
    }

    if (vm.sentRequests.isEmpty) {
      return const AppEmptyState(
        icon: Icons.send_outlined,
        title: 'Chưa gửi yêu cầu nào',
        message: 'Các yêu cầu ở ghép bạn đã gửi sẽ hiển thị ở đây.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: vm.sentRequests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final request = vm.sentRequests[index];
        final name = request.targetName.isNotEmpty
            ? request.targetName
            : 'Người dùng';
        final avatar =
            request.targetAvatar.isNotEmpty ? request.targetAvatar : null;

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
              if (request.inviteType == RoommateInviteType.profileInvite)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_add_alt_1_outlined,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          'Lời mời kết bạn',
                          style: AppTextStyles.labelSm
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
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
                            color: _statusSurface(request.status),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusText(request.status),
                            style: AppTextStyles.labelSm.copyWith(
                                color: _statusColor(request.status)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (request.createdAt != null)
                    Text(
                      _formatDate(request.createdAt!),
                      style: AppTextStyles.caption,
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed:
                        vm.isLoading ? null : () => _deleteRequest(request.id),
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger, size: 20),
                    tooltip: 'Hủy lời mời',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (request.message.isNotEmpty) ...[
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
                    request.message,
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
      },
    );
  }
}
