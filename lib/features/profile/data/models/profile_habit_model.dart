import 'package:flutter/material.dart';

class ProfileHabitModel {
  final String id;
  final String label;
  final String group;
  final double weight;
  final List<String> conflictsWith;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const ProfileHabitModel({
    required this.id,
    required this.label,
    required this.group,
    required this.weight,
    this.conflictsWith = const [],
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class ProfileHabitCatalog {
  // ─── 🧹 Vệ sinh & Không gian ──────────────────────────────────────────────
  static const _hygiene = <ProfileHabitModel>[
    ProfileHabitModel(
      id: 'no_smoking', label: 'Không hút thuốc',
      group: 'hygiene', weight: 3.0,
      icon: Icons.smoke_free_outlined,
      backgroundColor: Color(0xFFE8ECF2), foregroundColor: Color(0xFF7A8797),
    ),
    ProfileHabitModel(
      id: 'clean', label: 'Sạch sẽ',
      group: 'hygiene', weight: 2.0,
      icon: Icons.cleaning_services_outlined,
      backgroundColor: Color(0xFFD7EBFF), foregroundColor: Color(0xFF4F8AD9),
    ),
    ProfileHabitModel(
      id: 'neat', label: 'Gọn gàng',
      group: 'hygiene', weight: 2.0,
      icon: Icons.checkroom_outlined,
      backgroundColor: Color(0xFFDDF4EA), foregroundColor: Color(0xFF4DA77C),
    ),
  ];

  // ─── 🌙 Lịch sinh hoạt ────────────────────────────────────────────────────
  static const _schedule = <ProfileHabitModel>[
    ProfileHabitModel(
      id: 'sleep_early', label: 'Ngủ sớm',
      group: 'schedule', weight: 2.0, conflictsWith: ['stay_up_late'],
      icon: Icons.nightlight_round,
      backgroundColor: Color(0xFFDCEBFF), foregroundColor: Color(0xFF5B8FD8),
    ),
    ProfileHabitModel(
      id: 'stay_up_late', label: 'Thức khuya',
      group: 'schedule', weight: 2.0, conflictsWith: ['sleep_early'],
      icon: Icons.dark_mode_outlined,
      backgroundColor: Color(0xFFE9E5FF), foregroundColor: Color(0xFF7E6ED6),
    ),
    ProfileHabitModel(
      id: 'flexible_schedule', label: 'Giờ giấc linh hoạt',
      group: 'schedule', weight: 1.0,
      icon: Icons.schedule_outlined,
      backgroundColor: Color(0xFFE4EEFF), foregroundColor: Color(0xFF5C87D8),
    ),
    ProfileHabitModel(
      id: 'work_from_home', label: 'Làm việc tại nhà',
      group: 'schedule', weight: 1.0, conflictsWith: ['like_gathering'],
      icon: Icons.home_work_outlined,
      backgroundColor: Color(0xFFE0F0FF), foregroundColor: Color(0xFF4A7FC1),
    ),
  ];

  // ─── 👥 Xã giao ───────────────────────────────────────────────────────────
  static const _social = <ProfileHabitModel>[
    ProfileHabitModel(
      id: 'prefer_quiet', label: 'Thích yên tĩnh',
      group: 'social', weight: 2.0, conflictsWith: ['like_gathering'],
      icon: Icons.volume_off_outlined,
      backgroundColor: Color(0xFFE5EAFE), foregroundColor: Color(0xFF6E7FB3),
    ),
    ProfileHabitModel(
      id: 'less_partying', label: 'Ít tiệc tùng',
      group: 'social', weight: 2.0, conflictsWith: ['like_gathering'],
      icon: Icons.celebration_outlined,
      backgroundColor: Color(0xFFFFEDB8), foregroundColor: Color(0xFFD1A72E),
    ),
    ProfileHabitModel(
      id: 'like_gathering', label: 'Thích tụ tập bạn bè',
      group: 'social', weight: 1.0,
      conflictsWith: ['prefer_quiet', 'less_partying', 'work_from_home'],
      icon: Icons.groups_2_outlined,
      backgroundColor: Color(0xFFFFE0B8), foregroundColor: Color(0xFFCD8C2E),
    ),
    ProfileHabitModel(
      id: 'communicative', label: 'Giao tiếp tốt',
      group: 'social', weight: 1.0,
      icon: Icons.forum_outlined,
      backgroundColor: Color(0xFFFFE2AA), foregroundColor: Color(0xFFD4942D),
    ),
    ProfileHabitModel(
      id: 'no_visitor', label: 'Không muốn khách lạ vào phòng',
      group: 'social', weight: 2.0, conflictsWith: ['like_gathering'],
      icon: Icons.do_not_disturb_outlined,
      backgroundColor: Color(0xFFFFE5E5), foregroundColor: Color(0xFFD96B6B),
    ),
  ];

  // ─── 🍳 Sinh hoạt hàng ngày ───────────────────────────────────────────────
  static const _lifestyle = <ProfileHabitModel>[
    ProfileHabitModel(
      id: 'cook_at_home', label: 'Nấu ăn tại nhà',
      group: 'lifestyle', weight: 1.0, conflictsWith: ['no_cooking'],
      icon: Icons.soup_kitchen_outlined,
      backgroundColor: Color(0xFFFFD9DE), foregroundColor: Color(0xFFD97B87),
    ),
    ProfileHabitModel(
      id: 'no_cooking', label: 'Không nấu ăn',
      group: 'lifestyle', weight: 1.0, conflictsWith: ['cook_at_home'],
      icon: Icons.no_meals_outlined,
      backgroundColor: Color(0xFFF2E8E8), foregroundColor: Color(0xFF9B7272),
    ),
    ProfileHabitModel(
      id: 'study_often', label: 'Học tập thường xuyên',
      group: 'lifestyle', weight: 1.0,
      icon: Icons.menu_book_outlined,
      backgroundColor: Color(0xFFE7F0FF), foregroundColor: Color(0xFF5A82D8),
    ),
    ProfileHabitModel(
      id: 'like_midnight_snack', label: 'Thích ăn đêm',
      group: 'lifestyle', weight: 1.0,
      icon: Icons.ramen_dining_outlined,
      backgroundColor: Color(0xFFFFE6CC), foregroundColor: Color(0xFFD58C4B),
    ),
  ];

  // ─── 🐾 Thú cưng ──────────────────────────────────────────────────────────
  static const _pet = <ProfileHabitModel>[
    ProfileHabitModel(
      id: 'pet_friendly', label: 'Yêu động vật',
      group: 'pet', weight: 2.0,
      icon: Icons.pets_outlined,
      backgroundColor: Color(0xFFFFE3CF), foregroundColor: Color(0xFFDD9A57),
    ),
    ProfileHabitModel(
      id: 'has_pet', label: 'Có nuôi thú cưng',
      group: 'pet', weight: 2.0, conflictsWith: ['no_pet'],
      icon: Icons.cruelty_free_outlined,
      backgroundColor: Color(0xFFFFE8D8), foregroundColor: Color(0xFFDB9A58),
    ),
    ProfileHabitModel(
      id: 'no_pet', label: 'Không muốn có thú cưng',
      group: 'pet', weight: 2.0, conflictsWith: ['has_pet'],
      icon: Icons.pets_outlined,
      backgroundColor: Color(0xFFF0E8E8), foregroundColor: Color(0xFF9B6868),
    ),
  ];

  // ─── 💰 Tài chính ─────────────────────────────────────────────────────────
  static const _finance = <ProfileHabitModel>[
    ProfileHabitModel(
      id: 'employed', label: 'Có việc làm ổn định',
      group: 'finance', weight: 2.0,
      icon: Icons.work_outline_rounded,
      backgroundColor: Color(0xFFD8F4DF), foregroundColor: Color(0xFF4FAE68),
    ),
    ProfileHabitModel(
      id: 'split_expense', label: 'Sẵn sàng chia đều chi phí',
      group: 'finance', weight: 2.0,
      icon: Icons.receipt_long_outlined,
      backgroundColor: Color(0xFFDFF5EC), foregroundColor: Color(0xFF3DA873),
    ),
    ProfileHabitModel(
      id: 'budget_conscious', label: 'Tiết kiệm, chi tiêu hợp lý',
      group: 'finance', weight: 1.0,
      icon: Icons.savings_outlined,
      backgroundColor: Color(0xFFE8F5E9), foregroundColor: Color(0xFF4CAF50),
    ),
  ];

  // ─── Tổng hợp ─────────────────────────────────────────────────────────────
  static const List<ProfileHabitModel> all = [
    ..._hygiene,
    ..._schedule,
    ..._social,
    ..._lifestyle,
    ..._pet,
    ..._finance,
  ];

  static ProfileHabitModel? findById(String id) {
    try {
      return all.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }
}
