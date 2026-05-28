import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../viewmodels/roommate_request_viewmodel.dart';

class SendRequestScreen extends StatefulWidget {
  final String postId;
  final String ownerName;
  final String ownerAvatar;
  final String ownerAddress;

  const SendRequestScreen({
    super.key,
    required this.postId,
    required this.ownerName,
    required this.ownerAvatar,
    required this.ownerAddress,
  });

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  Future<void> _submitRequest() async {
    final viewModel = context.read<RoommateRequestViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await viewModel.sendRequest(
      postId: widget.postId,
      message: '',
    );

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gửi yêu cầu ở ghép thành công')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Gửi yêu cầu thất bại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoommateRequestViewModel>(
      builder: (context, viewModel, _) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  AppAvatar(
                    name: widget.ownerName,
                    avatarUrl: widget.ownerAvatar.isNotEmpty
                        ? widget.ownerAvatar
                        : null,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ownerName.isNotEmpty
                              ? widget.ownerName
                              : 'Chủ bài đăng',
                          style: AppTextStyles.labelLg,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.ownerAddress.isNotEmpty
                              ? widget.ownerAddress
                              : 'Chưa cập nhật',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Gửi yêu cầu',
                isLoading: viewModel.isLoading,
                onTap: viewModel.isLoading ? null : _submitRequest,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Huỷ',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
