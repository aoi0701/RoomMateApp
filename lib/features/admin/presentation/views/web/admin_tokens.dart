import 'package:flutter/material.dart';

abstract final class AC {
  static const primary           = Color(0xFF0050CB);
  static const primaryContainer  = Color(0xFF0066FF);
  static const primaryFixed      = Color(0xFFDAE1FF);
  static const primaryFixedDim   = Color(0xFFB3C5FF);

  static const surface                 = Color(0xFFF7F9FB);
  static const onSurface               = Color(0xFF191C1E);
  static const onSurfaceVariant        = Color(0xFF424656);
  static const surfaceLowest           = Color(0xFFFFFFFF);
  static const surfaceLow              = Color(0xFFF2F4F6);
  static const surfaceHighest          = Color(0xFFE0E3E5);
  static const outlineVariant          = Color(0xFFC2C6D8);

  static const errorContainer   = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const slate50  = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);

  static const blue50  = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);

  static const emerald50  = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald600 = Color(0xFF059669);

  static const orange100 = Color(0xFFFFEDD5);
  static const orange600 = Color(0xFFEA580C);
}

abstract final class AS {
  static const double sidebarW   = 256;
  static const double topbarH    = 52;
  static const double cardRadius = 12;
  static const double pagePad    = 32;
  static const double gap        = 24;
  static const double cardPad    = 24;
}

abstract final class AT {
  static const _h = 'Manrope';
  static const _b = 'Inter';

  static const brand = TextStyle(
    fontFamily: _h, fontSize: 20, fontWeight: FontWeight.w900,
    color: AC.blue700, letterSpacing: -0.5,
  );
  static const pageTitle = TextStyle(
    fontFamily: _h, fontSize: 34, fontWeight: FontWeight.w800,
    color: AC.onSurface, letterSpacing: -0.5,
  );
  static const sectionTitle = TextStyle(
    fontFamily: _h, fontSize: 20, fontWeight: FontWeight.w700,
    color: AC.onSurface,
  );
  static const kpiValue = TextStyle(
    fontFamily: _h, fontSize: 34, fontWeight: FontWeight.w800,
  );
  static const nav = TextStyle(
    fontFamily: _h, fontSize: 14, fontWeight: FontWeight.w600,
  );
  static const cardLabel = TextStyle(
    fontFamily: _b, fontSize: 11, fontWeight: FontWeight.w700,
    letterSpacing: 0.8, color: AC.slate500,
  );
  static const bodyMD = TextStyle(
    fontFamily: _b, fontSize: 13, fontWeight: FontWeight.w500,
    color: AC.onSurfaceVariant,
  );
  static const bodySM = TextStyle(
    fontFamily: _b, fontSize: 11, color: AC.slate500,
  );
  static const bodyXS = TextStyle(
    fontFamily: _b, fontSize: 10, color: AC.slate400,
  );
}
