import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import 'edit_basic_info_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final uid    = authVm.user?.uid ?? '';
    final email  = authVm.user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 28),

              // ── Hồ sơ ────────────────────────────────────────────────────
              _SectionLabel(title: 'Hồ sơ'),
              const SizedBox(height: 12),
              _SettingsCard(
                items: [
                  _SettingTile(
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.accent,
                    title: 'Chỉnh sửa thông tin',
                    subtitle: 'Tên, số điện thoại, địa chỉ, giới tính',
                    onTap: () => _openEditInfo(context, uid),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── Bảo mật ───────────────────────────────────────────────────
              _SectionLabel(title: 'Bảo mật'),
              const SizedBox(height: 12),
              _SettingsCard(
                items: [
                  _SettingTile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFF5F3FF),
                    title: 'Đổi mật khẩu',
                    subtitle: email.isNotEmpty
                        ? 'Gửi link đổi mật khẩu về $email'
                        : 'Gửi link đổi mật khẩu về email của bạn',
                    isLoading: authVm.isLoading,
                    onTap: authVm.isLoading
                        ? null
                        : () => _sendPasswordReset(context, authVm, email),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ── Nguy hiểm ─────────────────────────────────────────────────
              _SectionLabel(title: 'Nguy hiểm'),
              const SizedBox(height: 12),
              _DangerCard(uid: uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Cài đặt tài khoản',
            textAlign: TextAlign.center,
            style: AppTextStyles.h2,
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }

  Future<void> _openEditInfo(BuildContext context, String uid) async {
    final profileVm = context.read<UserProfileViewModel>();
    final user = await profileVm.getUserProfile(uid);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBasicInfoScreen(
          uid: uid,
          initialFullName: user?.fullName ?? '',
          initialPhone: user?.phone ?? '',
          initialAddress: user?.address ?? '',
          initialGender: user?.gender ?? '',
        ),
      ),
    );
  }

  Future<void> _sendPasswordReset(
    BuildContext context,
    AuthViewModel authVm,
    String email,
  ) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy email tài khoản')),
      );
      return;
    }
    final ok = await authVm.resetPassword(email);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã gửi link đổi mật khẩu về $email'
              : (authVm.errorMessage ?? 'Gửi email thất bại'),
        ),
      ),
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.labelSm.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingTile> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
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
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              items[i],
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                  color: AppColors.border,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                ),
              )
            : Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(title, style: AppTextStyles.labelLg),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 24,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

// Danger card cần Consumer để phản ứng với isDeletingAccount
class _DangerCard extends StatelessWidget {
  final String uid;
  const _DangerCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileViewModel>(
      builder: (context, vm, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: vm.isDeletingAccount
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.danger,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                      size: 24,
                    ),
            ),
            title: Text(
              'Xóa tài khoản',
              style: AppTextStyles.labelLg.copyWith(color: AppColors.danger),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Vô hiệu hóa và xóa toàn bộ dữ liệu của bạn',
                style: AppTextStyles.caption,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: AppColors.textSecondary,
            ),
            onTap: vm.isDeletingAccount
                ? null
                : () => _confirmDelete(context, uid, vm),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String uid,
    UserProfileViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa tài khoản'),
        content: const Text(
          'Tài khoản của bạn sẽ bị vô hiệu hóa ngay lập tức và toàn bộ dữ liệu liên quan (bài đăng, nhóm phòng, tin nhắn...) sẽ bị xóa.\n\nHành động này không thể hoàn tác. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await vm.deleteAccount(uid);
    if (!context.mounted) return;
    if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage!)),
      );
    }
    // UserSessionRepository tự phát hiện deleted=true và kick về màn login.
  }
}
