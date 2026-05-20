import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../home/presentation/views/user_home_screen.dart';
import '../../data/mappers/habit_roommate_criteria_mapper.dart';
import '../../data/models/profile_habit_model.dart';
import '../viewmodels/user_profile_viewmodel.dart';

class CompleteProfileFlowScreen extends StatefulWidget {
  const CompleteProfileFlowScreen({super.key});

  @override
  State<CompleteProfileFlowScreen> createState() =>
      _CompleteProfileFlowScreenState();
}

class _CompleteProfileFlowScreenState extends State<CompleteProfileFlowScreen> {
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final Set<String> _selectedHabits = <String>{};
  int _currentStep = 0;
  String? _selectedGender;
  bool _isLoadingInitialData = true;

  static const _genderOptions = ['Nam', 'Nữ', 'Khác'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid == null) {
      if (mounted) {
        setState(() {
          _isLoadingInitialData = false;
        });
      }
      return;
    }

    final profile = await context.read<UserProfileViewModel>().getUserProfile(uid);
    if (!mounted) return;

    _phoneController.text = profile?.phone ?? '';
    _addressController.text = profile?.address ?? '';
    if ((profile?.gender ?? '').trim().isNotEmpty) {
      _selectedGender = profile!.gender;
    }
    _selectedHabits
      ..clear()
      ..addAll(profile?.habits ?? const <String>[]);

    setState(() {
      _isLoadingInitialData = false;
    });
  }

  List<String> get _criteriaPreview =>
      HabitRoommateCriteriaMapper.mapHabitsToRoommateCriteria(
        _selectedHabits.toList(),
      );

  void _goNext() {
    if (_currentStep == 0) {
      if (_phoneController.text.trim().isEmpty ||
          _addressController.text.trim().isEmpty ||
          (_selectedGender ?? '').trim().isEmpty) {
        _showMessage('Vui lòng điền đủ số điện thoại, giới tính và khu vực.');
        return;
      }
    }

    if (_currentStep == 1 && _selectedHabits.isEmpty) {
      _showMessage('Hãy chọn ít nhất một thói quen để tiếp tục.');
      return;
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  void _goBack() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _currentStep -= 1;
    });
  }

  Future<void> _submit() async {
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid == null) return;

    if (_criteriaPreview.isEmpty) {
      _showMessage('Chưa thể tạo tiêu chí bạn cùng phòng. Hãy chọn thêm thói quen.');
      return;
    }

    final success = await context.read<UserProfileViewModel>().completeProfile(
          uid: uid,
          phone: _phoneController.text,
          address: _addressController.text,
          gender: _selectedGender ?? '',
          habits: _selectedHabits.toList(),
        );

    if (!mounted) return;

    if (!success) {
      _showMessage(
        context.read<UserProfileViewModel>().errorMessage ??
            'Không thể hoàn thiện hồ sơ',
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserProfileViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: _goBack,
        ),
        title: Text(
          'Hoàn thiện hồ sơ',
          style: AppTextStyles.h2,
        ),
      ),
      body: _isLoadingInitialData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepHeader(currentStep: _currentStep),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildCurrentStep(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      label: _currentStep == 2 ? 'Hoàn tất' : 'Tiếp tục',
                      isLoading: vm.isSubmittingProfile,
                      onTap: vm.isSubmittingProfile
                          ? null
                          : (_currentStep == 2 ? _submit : _goNext),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildHabitsStep();
      default:
        return _buildCriteriaPreviewStep();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin cơ bản', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text(
          'Thông tin này giúp hồ sơ của bạn đầy đủ hơn khi người khác xem.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: 'Số điện thoại',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Khu vực bạn đang muốn ở',
        ),
        const SizedBox(height: 16),
        Text('Giới tính', style: AppTextStyles.label),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _genderOptions.map((gender) {
            final selected = _selectedGender == gender;
            return ChoiceChip(
              label: Text(gender),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _selectedGender = gender;
                });
              },
              labelStyle: AppTextStyles.label.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHabitsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thói quen sinh hoạt', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text(
          'Chọn những thói quen phù hợp với bạn nhất. Hệ thống sẽ dùng chúng để gợi ý tiêu chí bạn cùng phòng.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ProfileHabitCatalog.all.map((habit) {
            final selected = _selectedHabits.contains(habit.id);
            return _OnboardingHabitChip(
              habit: habit,
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedHabits.remove(habit.id);
                  } else {
                    _selectedHabits.add(habit.id);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCriteriaPreviewStep() {
    final criteria = _criteriaPreview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tiêu chí bạn cùng phòng', style: AppTextStyles.h1),
        const SizedBox(height: 8),
        Text(
          'Dựa trên thói quen bạn vừa chọn, RoomMate đã gợi ý các tiêu chí phù hợp dưới đây.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        if (criteria.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Chưa có tiêu chí nào được tạo. Bạn có thể quay lại để chọn thêm thói quen.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          )
        else
          ...criteria.map(
            (item) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: AppTextStyles.label)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            hintText: label,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int currentStep;

  const _StepHeader({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Thông tin cơ bản',
      'Thói quen',
      'Tiêu chí',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bước ${currentStep + 1}/3',
          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(labels.length, (index) {
            final isActive = index <= currentStep;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(labels[currentStep], style: AppTextStyles.h2),
      ],
    );
  }
}

class _OnboardingHabitChip extends StatelessWidget {
  final ProfileHabitModel habit;
  final bool selected;
  final VoidCallback onTap;

  const _OnboardingHabitChip({
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
        width: (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? habit.backgroundColor : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? habit.foregroundColor : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(habit.icon, color: habit.foregroundColor, size: 24),
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
