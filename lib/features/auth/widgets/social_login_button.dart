import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String imagePath;
  final VoidCallback? onTap;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.inputBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}