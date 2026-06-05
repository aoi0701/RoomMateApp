import 'package:flutter/material.dart';

// Kiểm tra kích thước màn hình để layout responsive: mobile (<768), tablet (768-1024), desktop (>=1024)
class Responsive {
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 768;
}
