import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../viewmodels/user_profile_viewmodel.dart';

class EditBasicInfoScreen extends StatefulWidget {
  final String uid;
  final String initialFullName;
  final String initialPhone;
  final String initialAddress;
  final String initialGender;

  const EditBasicInfoScreen({
    super.key,
    required this.uid,
    required this.initialFullName,
    required this.initialPhone,
    required this.initialAddress,
    required this.initialGender,
  });

  @override
  State<EditBasicInfoScreen> createState() => _EditBasicInfoScreenState();
}

class _EditBasicInfoScreenState extends State<EditBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialFullName);
    _phoneController    = TextEditingController(text: widget.initialPhone);
    _addressController  = TextEditingController(text: widget.initialAddress);
    final g = widget.initialGender.trim();
    _selectedGender = (g == 'Nam' || g == 'Nữ' || g == 'Khác') ? g : null;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Vui lòng nhập họ tên';
    if (t.length < 2) return 'Họ tên phải có ít nhất 2 ký tự';
    return null;
  }

  String? _validatePhone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(t)) return 'SĐT phải gồm 10–11 chữ số';
    return null;
  }

  String? _validateAddress(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Vui lòng nhập địa chỉ';
    if (t.length < 3) return 'Địa chỉ quá ngắn';
    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn giới tính')),
      );
      return;
    }
    final vm = context.read<UserProfileViewModel>();
    final success = await vm.updateBasicInfo(
      uid: widget.uid,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      gender: _selectedGender!,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật thông tin thành công')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Cập nhật thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserProfileViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _NavButton(onPressed: () => Navigator.maybePop(context)),
                  Expanded(
                    child: Text(
                      'Chỉnh sửa thông tin',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h2,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: _inputDecoration(
                          label: 'Họ tên',
                          icon: Icons.person_outline_rounded,
                        ),
                        validator: _validateFullName,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: _inputDecoration(
                          label: 'Số điện thoại',
                          icon: Icons.phone_outlined,
                        ),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        textInputAction: TextInputAction.done,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                        decoration: _inputDecoration(
                          label: 'Địa chỉ',
                          icon: Icons.location_on_outlined,
                        ),
                        validator: _validateAddress,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: _inputDecoration(
                          label: 'Giới tính',
                          icon: Icons.wc_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                          DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                          DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                label: 'Lưu thay đổi',
                isLoading: vm.isUpdatingInfo,
                onTap: vm.isUpdatingInfo ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NavButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}
