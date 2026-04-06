import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/roommate_request_model.dart';
import '../viewmodels/roommate_request_viewmodel.dart';

class ReceivedRequestsScreen extends StatefulWidget {
  const ReceivedRequestsScreen({super.key});

  @override
  State<ReceivedRequestsScreen> createState() => _ReceivedRequestsScreenState();
}

class _ReceivedRequestsScreenState extends State<ReceivedRequestsScreen> {
  static const Color primaryBlue = Color(0xFF3B6EF5);
  static const Color bgColor = Color(0xFFF5F7FB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color lightBlue = Color(0xFFEAF2FF);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color warningOrange = Color(0xFFF59E0B);

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
        return successGreen;
      case RoommateRequestStatus.rejected:
        return errorRed;
      case RoommateRequestStatus.pending:
        return warningOrange;
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
          backgroundColor: bgColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            centerTitle: true,
            title: const Text(
              'Yêu cầu đã nhận',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            iconTheme: const IconThemeData(color: textPrimary),
          ),
          body: SafeArea(
            child: requests.isEmpty
                ? const _EmptyState()
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: lightBlue,
                                  backgroundImage: request.requesterAvatar.isNotEmpty
                                      ? NetworkImage(request.requesterAvatar)
                                      : null,
                                  child: request.requesterAvatar.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: primaryBlue,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.requesterName.isNotEmpty
                                            ? request.requesterName
                                            : 'Người dùng',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFF),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                request.message.isNotEmpty
                                    ? request.message
                                    : 'Không có lời nhắn',
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (request.status == RoommateRequestStatus.pending)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: viewModel.isLoading
                                          ? null
                                          : () => _rejectRequest(request.id),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: errorRed,
                                        side: const BorderSide(color: errorRed),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text(
                                        'Từ chối',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: viewModel.isLoading
                                          ? null
                                          : () => _acceptRequest(request.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      child: const Text(
                                        'Chấp nhận',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  static const Color primaryBlue = Color(0xFF3B6EF5);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color lightBlue = Color(0xFFEAF2FF);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                color: primaryBlue,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chưa có yêu cầu nào',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Các yêu cầu ở ghép gửi đến bạn sẽ hiển thị ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
