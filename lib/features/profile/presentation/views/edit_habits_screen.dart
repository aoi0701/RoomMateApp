import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F6FA),
        surfaceTintColor: const Color(0xFFF5F6FA),
        centerTitle: true,
        title: const Text(
          'Chỉnh sửa thói quen',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn những thói quen phù hợp với bạn. Sau khi lưu, hệ thống sẽ tự đồng bộ sang Tiêu chí bạn cùng phòng.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF6B7280),
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
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: vm.isSavingHabits ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: vm.isSavingHabits
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu thói quen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
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
          color: selected ? habit.backgroundColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? habit.foregroundColor : const Color(0xFFD9DFEA),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              habit.icon,
              color: habit.foregroundColor,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                habit.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  height: 1.25,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: habit.foregroundColor,
              ),
          ],
        ),
      ),
    );
  }
}
