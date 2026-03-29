import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_text_field.dart';
import 'check_email_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Image.asset(
                'assets/images/logohome.png',
                width: 74,
                height: 74,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 22),
              const Text(
                'Quên mật khẩu',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nhập email của bạn để nhận liên kết\nđặt lại mật khẩu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              AuthTextField(
                hintText: 'Địa chỉ email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                controller: _emailController,
              ),
              const SizedBox(height: 8),
              _buildPrimaryButton(
                text: 'Gửi email đặt lại mật khẩu',
                      onTap: () async {
                        final email = _emailController.text.trim();

                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập email')),
                          );
                          return;
                        }

                        final vm = AuthViewModel();

                        try {
                          await vm.resetPassword(email);

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã gửi email đặt lại mật khẩu')),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckEmailScreen(email: email),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gửi email thất bại: $e')),
                          );
                        }
                      },
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Quay lại đăng nhập',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}