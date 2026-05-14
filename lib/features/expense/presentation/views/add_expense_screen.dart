import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../../room_group/data/models/room_group_model.dart';
import '../viewmodels/expense_viewmodel.dart';

class AddExpenseScreen extends StatefulWidget {
  final RoomGroupModel roomGroup;

  const AddExpenseScreen({super.key, required this.roomGroup});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late Set<String> _selectedParticipants;

  @override
  void initState() {
    super.initState();
    _selectedParticipants = Set.from(widget.roomGroup.memberIds);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUserId = context.read<AuthViewModel>().user?.uid ?? '';

    final nonPayers = _selectedParticipants.where((id) => id != currentUserId).toList();
    if (nonPayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một người khác để chia tiền'),
        ),
      );
      return;
    }

    final amount = double.tryParse(
          _amountController.text.trim().replaceAll('.', ''),
        ) ??
        0;

    final vm = context.read<ExpenseViewModel>();
    final success = await vm.addExpense(
      roomGroupId: widget.roomGroup.id,
      title: _titleController.text.trim(),
      amount: amount,
      paidBy: currentUserId,
      participantIds: _selectedParticipants.toList(),
      visibleToUserIds: widget.roomGroup.memberIds,
      note: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Thêm khoản chi thất bại')),
      );
    }
  }

  InputDecoration _fieldDecoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.textHint,
        fontSize: 14,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
          : null,
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthViewModel>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thêm khoản chi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ExpenseViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    title: 'Thông tin khoản chi',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                          decoration: _fieldDecoration(
                            'VD: Tiền điện tháng 5',
                            prefixIcon: Icons.receipt_outlined,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Vui lòng nhập tên khoản chi'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _fieldDecoration(
                            'VD: 300000',
                            prefixIcon: Icons.payments_outlined,
                          ),
                          validator: (v) {
                            final amount = double.tryParse(
                              v?.replaceAll('.', '') ?? '',
                            );
                            if (amount == null || amount <= 0) {
                              return 'Vui lòng nhập số tiền hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 2,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                          decoration: _fieldDecoration(
                            'Ghi chú thêm... (tuỳ chọn)',
                            prefixIcon: Icons.notes_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Người trả',
                    child: _UserNameTile(userId: currentUserId),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Chia tiền với',
                    child: Column(
                      children: widget.roomGroup.memberIds.map((uid) {
                        final isSelected = _selectedParticipants.contains(uid);
                        return _ParticipantTile(
                          userId: uid,
                          isSelected: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedParticipants.add(uid);
                              } else {
                                _selectedParticipants.remove(uid);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: 'Lưu khoản chi',
                    isLoading: vm.isLoading,
                    onTap: _submit,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _UserNameTile extends StatelessWidget {
  final String userId;
  const _UserNameTile({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: context.read<UserProfileViewModel>().getUserProfileStream(userId),
      builder: (context, snapshot) {
        String name = 'Người dùng';
        String? avatarUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['fullName'] ?? 'Người dùng';
          avatarUrl = data?['avatarUrl'];
        }

        return Row(
          children: [
            AppAvatar(name: name, avatarUrl: avatarUrl, size: 36),
            const SizedBox(width: 12),
            Text(name, style: AppTextStyles.labelLg),
          ],
        );
      },
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final String userId;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _ParticipantTile({
    required this.userId,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: context.read<UserProfileViewModel>().getUserProfileStream(userId),
      builder: (context, snapshot) {
        String name = 'Người dùng';
        String? avatarUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['fullName'] ?? 'Người dùng';
          avatarUrl = data?['avatarUrl'];
        }

        return GestureDetector(
          onTap: () => onChanged(!isSelected),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                AppAvatar(name: name, avatarUrl: avatarUrl, size: 36),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: AppTextStyles.label)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.inputBorder,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
