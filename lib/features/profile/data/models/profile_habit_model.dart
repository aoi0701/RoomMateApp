import 'package:flutter/material.dart';

class ProfileHabitModel {
  final String id;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const ProfileHabitModel({
    required this.id,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

class ProfileHabitCatalog {
  static const List<ProfileHabitModel> all = [
    ProfileHabitModel(
      id: 'clean',
      label: 'Sạch sẽ',
      icon: Icons.cleaning_services_outlined,
      backgroundColor: Color(0xFFD7EBFF),
      foregroundColor: Color(0xFF4F8AD9),
    ),
    ProfileHabitModel(
      id: 'no_smoking',
      label: 'Không hút thuốc',
      icon: Icons.smoke_free_outlined,
      backgroundColor: Color(0xFFE8ECF2),
      foregroundColor: Color(0xFF7A8797),
    ),
    ProfileHabitModel(
      id: 'sleep_early',
      label: 'Ngủ sớm',
      icon: Icons.nightlight_round,
      backgroundColor: Color(0xFFDCEBFF),
      foregroundColor: Color(0xFF5B8FD8),
    ),
    ProfileHabitModel(
      id: 'prefer_quiet',
      label: 'Thích yên tĩnh',
      icon: Icons.volume_off_outlined,
      backgroundColor: Color(0xFFE5EAFE),
      foregroundColor: Color(0xFF6E7FB3),
    ),
    ProfileHabitModel(
      id: 'study_often',
      label: 'Học tập thường xuyên',
      icon: Icons.menu_book_outlined,
      backgroundColor: Color(0xFFE7F0FF),
      foregroundColor: Color(0xFF5A82D8),
    ),
    ProfileHabitModel(
      id: 'pet_friendly',
      label: 'Yêu động vật',
      icon: Icons.pets_outlined,
      backgroundColor: Color(0xFFFFE3CF),
      foregroundColor: Color(0xFFDD9A57),
    ),
    ProfileHabitModel(
      id: 'has_pet',
      label: 'Có nuôi thú cưng',
      icon: Icons.pets_outlined,
      backgroundColor: Color(0xFFFFE8D8),
      foregroundColor: Color(0xFFDB9A58),
    ),
    ProfileHabitModel(
      id: 'neat',
      label: 'Gọn gàng',
      icon: Icons.checkroom_outlined,
      backgroundColor: Color(0xFFDDF4EA),
      foregroundColor: Color(0xFF4DA77C),
    ),
    ProfileHabitModel(
      id: 'stay_up_late',
      label: 'Thức khuya',
      icon: Icons.dark_mode_outlined,
      backgroundColor: Color(0xFFE9E5FF),
      foregroundColor: Color(0xFF7E6ED6),
    ),
    ProfileHabitModel(
      id: 'cook_at_home',
      label: 'Nấu ăn tại nhà',
      icon: Icons.soup_kitchen_outlined,
      backgroundColor: Color(0xFFFFD9DE),
      foregroundColor: Color(0xFFD97B87),
    ),
    ProfileHabitModel(
      id: 'less_partying',
      label: 'Ít tiệc tùng',
      icon: Icons.celebration_outlined,
      backgroundColor: Color(0xFFFFEDB8),
      foregroundColor: Color(0xFFD1A72E),
    ),
    ProfileHabitModel(
      id: 'like_gathering',
      label: 'Thích tụ tập bạn bè',
      icon: Icons.groups_2_outlined,
      backgroundColor: Color(0xFFFFE0B8),
      foregroundColor: Color(0xFFCD8C2E),
    ),
    ProfileHabitModel(
      id: 'flexible_schedule',
      label: 'Giờ giấc linh hoạt',
      icon: Icons.schedule_outlined,
      backgroundColor: Color(0xFFE4EEFF),
      foregroundColor: Color(0xFF5C87D8),
    ),
    ProfileHabitModel(
      id: 'like_midnight_snack',
      label: 'Thích ăn đêm',
      icon: Icons.ramen_dining_outlined,
      backgroundColor: Color(0xFFFFE6CC),
      foregroundColor: Color(0xFFD58C4B),
    ),
    ProfileHabitModel(
      id: 'no_cooking',
      label: 'Không nấu ăn',
      icon: Icons.no_meals_outlined,
      backgroundColor: Color(0xFFF2E8E8),
      foregroundColor: Color(0xFF9B7272),
    ),
    ProfileHabitModel(
      id: 'employed',
      label: 'Có việc làm',
      icon: Icons.work_outline_rounded,
      backgroundColor: Color(0xFFD8F4DF),
      foregroundColor: Color(0xFF4FAE68),
    ),
    ProfileHabitModel(
      id: 'communicative',
      label: 'Giao tiếp tốt',
      icon: Icons.forum_outlined,
      backgroundColor: Color(0xFFFFE2AA),
      foregroundColor: Color(0xFFD4942D),
    ),
  ];

  static ProfileHabitModel? findById(String id) {
    try {
      return all.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
