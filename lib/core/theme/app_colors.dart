import 'package:flutter/material.dart';

class AppColors {
  // Primary — Cerulean Royal Blue (Tailwind Blue scale, no purple undertone)
  static const Color primary = Color(0xFF2563EB);       // Blue-600, 4.73:1 on white
  static const Color primaryDark = Color(0xFF1D4ED8);   // Blue-700, gradient / pressed
  static const Color primaryLight = Color(0xFF60A5FA);  // Blue-400, decorative
  static const Color primarySurface = Color(0xFFDBEAFE); // Blue-100, chip / tag bg

  // Backgrounds
  static const Color background = Color(0xFFF7F8FC);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Border & Divider
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputFill = Color(0xFFF8FAFC);
  static const Color inputBorder = Color(0xFFE2E8F0);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color successText = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF9C3);
  static const Color warningText = Color(0xFFB45309);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSurface = Color(0xFFFEE2E2);
  static const Color dangerText = Color(0xFFDC2626);

  // Utility
  static const Color white = Colors.white;
  static const Color black = Color(0xFF0F172A);

  // Accent shades
  static const Color accent = Color(0xFFEFF6FF);        // Blue-50, lightest bg tint
  static const Color accentMint = Color(0xFFECFDF5);
  static const Color accentAmber = Color(0xFFFEF3C7);
}
