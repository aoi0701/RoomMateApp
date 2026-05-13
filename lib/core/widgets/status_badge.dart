import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum BadgeType { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
    this.icon,
  });

  Color get _bg {
    switch (type) {
      case BadgeType.success:
        return AppColors.successSurface;
      case BadgeType.warning:
        return AppColors.warningSurface;
      case BadgeType.danger:
        return AppColors.dangerSurface;
      case BadgeType.info:
        return AppColors.accent;
      case BadgeType.neutral:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get _fg {
    switch (type) {
      case BadgeType.success:
        return AppColors.successText;
      case BadgeType.warning:
        return AppColors.warningText;
      case BadgeType.danger:
        return AppColors.dangerText;
      case BadgeType.info:
        return AppColors.primary;
      case BadgeType.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: _fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: _fg,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
