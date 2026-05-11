import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
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
    if (_selectedParticipants.isEmpty) {
      _showError('Vui lòng chọn ít nhất một người tham gia');
      return;
    }

    final currentUserId = context.read<AuthViewModel>().user?.uid ?? '';
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
      note: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      _showError(vm.errorMessage ?? 'Thêm khoản chi thất bại');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthViewModel>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Thêm khoản chi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Consumer<ExpenseViewModel>(
          builder: (context, vm, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Tên khoản chi'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: _inputDecoration('VD: Tiền điện tháng 5'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Vui lòng nhập tên khoản chi'
                                    : null,
                          ),
                          const SizedBox(height: 20),
                          _buildLabel('Số tiền (đ)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _inputDecoration('VD: 300000'),
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
                          const SizedBox(height: 20),
                          _buildLabel('Ghi chú (tuỳ chọn)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _noteController,
                            maxLines: 2,
                            decoration: _inputDecoration('Ghi chú thêm...'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Người trả'),
                          const SizedBox(height: 10),
                          _UserNameTile(userId: currentUserId),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Người tham gia chia tiền'),
                          const SizedBox(height: 8),
                          ...widget.roomGroup.memberIds.map((uid) {
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.primary,
                              value: _selectedParticipants.contains(uid),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedParticipants.add(uid);
                                  } else {
                                    _selectedParticipants.remove(uid);
                                  }
                                });
                              },
                              title: _UserNameTile(userId: uid),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: vm.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: vm.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Lưu khoản chi',
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
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
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
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
      stream: context
          .read<UserProfileViewModel>()
          .getUserProfileStream(userId),
      builder: (context, snapshot) {
        String name = 'Người dùng';
        String? avatarUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data =
              snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['fullName'] ?? 'Người dùng';
          avatarUrl = data?['avatarUrl'];
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFEAF2FF),
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0] : 'U',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
