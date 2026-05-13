import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/profile_habit_model.dart';
import '../viewmodels/user_profile_viewmodel.dart';

class EditHabitsScreen extends StatefulWidget {
  final List<String> initialHabits;

  const EditHabitsScreen({
    super.key,
    required this.initialHabits,
  });

  @override
  State<EditHabitsScreen> createState() => _EditHabitsScreenState();
}

class _EditHabitsScreenState extends State<EditHabitsScreen> {
  late final Set<String> _selectedHabits;

  @override
  void initState() {
    super.initState();
    _selectedHabits = widget.initialHabits.toSet();
  }

  void _toggleHabit(String habitId) {
    setState(() {
      if (_selectedHabits.contains(habitId)) {
        _selectedHabits.remove(habitId);
      } else {
        _selectedHabits.add(habitId);
      }
    });
  }

  Future<void> _save() async {
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid == null) return;

    final success = await context.read<UserProfileViewModel>().updateHabits(
          uid: uid,
          habits: _selectedHabits.toList(),
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<UserProfileViewModel>().errorMessage ??
                'Lưu thói quen thất bại',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserProfileViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chỉnh sửa thói quen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn những thói quen phù hợp với bạn. Sau khi lưu, hệ thống sẽ tự đồng bộ sang Tiêu chí bạn cùng phòng.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ProfileHabitCatalog.all.map((habit) {
                      final selected = _selectedHabits.contains(habit.id);
                      return _EditableHabitChip(
                        habit: habit,
                        selected: selected,
                        onTap: () => _toggleHabit(habit.id),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: 'Lưu thói quen',
                isLoading: vm.isSavingHabits,
                onTap: vm.isSavingHabits ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableHabitChip extends StatelessWidget {
  final ProfileHabitModel habit;
  final bool selected;
  final VoidCallback onTap;

  const _EditableHabitChip({
    required this.habit,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: (MediaQuery.of(context).size.width - 48) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? habit.backgroundColor : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? habit.foregroundColor : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(habit.icon, color: habit.foregroundColor, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                habit.label,
                style: AppTextStyles.label.copyWith(height: 1.25),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 18, color: habit.foregroundColor),
          ],
        ),
      ),
    );
  }
}
