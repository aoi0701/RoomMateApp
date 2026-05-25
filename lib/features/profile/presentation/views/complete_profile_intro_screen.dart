import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/presentation/views/user_home_screen.dart';
import 'complete_profile_flow_screen.dart';

class CompleteProfileIntroScreen extends StatelessWidget {
  const CompleteProfileIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chào mừng bạn đến với RoomMate',
                style: AppTextStyles.displaySm,
              ),
              const SizedBox(height: 12),
              Text(
                'Chúng mình đã lấy tên, email và ảnh đại diện từ Google. Chỉ cần thêm vài thông tin nữa để gợi ý bạn ở ghép phù hợp hơn.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Bạn vẫn có thể vào app ngay, nhưng một số gợi ý sẽ chưa chính xác nếu hồ sơ còn thiếu.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Hoàn thiện hồ sơ',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompleteProfileFlowScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppSecondaryButton(
                label: 'Để sau',
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
