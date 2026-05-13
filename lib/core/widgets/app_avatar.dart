import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final bool showBorder;

  const AppAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 48,
    this.showBorder = false,
  });

  Color _gradientStart(String name) {
    if (name.isEmpty) return AppColors.primary;
    final colors = [
      const Color(0xFF5B6AF0),
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
      const Color(0xFFD97706),
      const Color(0xFF0891B2),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  Color _gradientEnd(String name) {
    if (name.isEmpty) return AppColors.primaryDark;
    final colors = [
      const Color(0xFF4756D0),
      const Color(0xFF6D28D9),
      const Color(0xFF047857),
      const Color(0xFFB91C1C),
      const Color(0xFFB45309),
      const Color(0xFF0E7490),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    Widget content;
    if (hasImage) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, _) => _buildFallback(),
        ),
      );
    } else {
      content = _buildFallback();
    }

    if (showBorder) {
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_gradientStart(name), _gradientEnd(name)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: AppTextStyles.label.copyWith(
            color: Colors.white,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
