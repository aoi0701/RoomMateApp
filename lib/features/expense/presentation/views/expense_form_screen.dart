import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/user_name_cache.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/user_name_widgets.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../room_group/data/models/room_group_model.dart';
import '../../data/models/expense_model.dart';
import '../viewmodels/expense_viewmodel.dart';

class ExpenseFormScreen extends StatefulWidget {
  final RoomGroupModel roomGroup;
  /// null → add new expense; non-null → edit existing expense.
  final ExpenseModel? expense;

  const ExpenseFormScreen({
    super.key,
    required this.roomGroup,
    this.expense,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late Set<String> _selectedParticipants;
  late SplitType _splitType;
  final Map<String, TextEditingController> _customControllers = {};

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _titleController = TextEditingController(text: expense.title);
      _amountController = TextEditingController(
        text: expense.amount.toStringAsFixed(0),
      );
      _noteController = TextEditingController(text: expense.note);
      _selectedParticipants = Set.from(expense.participantIds);
      _splitType = expense.splitType;
      for (final uid in widget.roomGroup.memberIds) {
        final existing = expense.customSplits[uid];
        _customControllers[uid] = TextEditingController(
          text: existing != null ? existing.toStringAsFixed(0) : '',
        );
      }
    } else {
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedParticipants = Set.from(widget.roomGroup.memberIds);
      _splitType = SplitType.equal;
      for (final uid in widget.roomGroup.memberIds) {
        _customControllers[uid] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _parsedAmount =>
      double.tryParse(_amountController.text.trim().replaceAll('.', '')) ?? 0;

  double _calculateCustomTotal(String currentUserId) {
    double total = 0;
    for (final uid in _selectedParticipants) {
      if (uid == currentUserId) continue;
      total += double.tryParse(_customControllers[uid]?.text ?? '') ?? 0;
    }
    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUserId = context.read<AuthViewModel>().user?.uid ?? '';

    final nonPayers =
        _selectedParticipants.where((id) => id != currentUserId).toList();
    if (nonPayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một người khác để chia tiền'),
        ),
      );
      return;
    }

    final amount = _parsedAmount;

    Map<String, double> customSplits = {};
    if (_splitType == SplitType.custom) {
      double sum = 0;
      for (final uid in nonPayers) {
        final val =
            double.tryParse(_customControllers[uid]?.text.trim() ?? '') ?? 0;
        customSplits[uid] = val;
        sum += val;
      }
      final remaining = amount - sum;
      if (remaining < -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tổng vượt quá số tiền khoản chi')),
        );
        return;
      }
      if (remaining > 0) {
        customSplits[currentUserId] = remaining;
      }
    }

    final vm = context.read<ExpenseViewModel>();
    final bool success;
    if (_isEditing) {
      success = await vm.updateExpense(
        expenseId: widget.expense!.id,
        roomGroupId: widget.roomGroup.id,
        title: _titleController.text.trim(),
        amount: amount,
        paidBy: currentUserId,
        participantIds: _selectedParticipants.toList(),
        note: _noteController.text.trim(),
        splitType: _splitType,
        customSplits: customSplits,
      );
    } else {
      success = await vm.addExpense(
        roomGroupId: widget.roomGroup.id,
        title: _titleController.text.trim(),
        amount: amount,
        paidBy: currentUserId,
        participantIds: _selectedParticipants.toList(),
        note: _noteController.text.trim(),
        splitType: _splitType,
        customSplits: customSplits,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, _isEditing ? true : null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.errorMessage ??
                (_isEditing ? 'Cập nhật khoản chi thất bại' : 'Thêm khoản chi thất bại'),
          ),
        ),
      );
    }
  }

  InputDecoration _fieldDecoration(String hint, {IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textHint, fontSize: 14),
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
        title: Text(_isEditing ? 'Chỉnh sửa khoản chi' : 'Thêm khoản chi'),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14),
                          decoration: _fieldDecoration(
                            'Nội dung',
                            prefixIcon: Icons.receipt_outlined,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
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
                          onChanged: (_) => setState(() {}),
                          decoration: _fieldDecoration(
                            'Số tiền',
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
                        if (_splitType == SplitType.equal &&
                            _parsedAmount > 0 &&
                            _selectedParticipants.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Mỗi người: ${FormatUtils.formatMoney(_parsedAmount / _selectedParticipants.length)}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
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
                    child: UserNameTile(userId: currentUserId),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Chia tiền với',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedButton<SplitType>(
                          segments: const [
                            ButtonSegment(
                              value: SplitType.equal,
                              label: Text('Chia đều'),
                              icon: Icon(Icons.balance_rounded),
                            ),
                            ButtonSegment(
                              value: SplitType.custom,
                              label: Text('Tuỳ chỉnh'),
                              icon: Icon(Icons.tune_rounded),
                            ),
                          ],
                          selected: {_splitType},
                          onSelectionChanged: (val) {
                            setState(() => _splitType = val.first);
                          },
                          style: ButtonStyle(
                            textStyle: WidgetStatePropertyAll(
                              GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_splitType == SplitType.equal)
                          ...widget.roomGroup.memberIds.map((uid) {
                            final isSelected =
                                _selectedParticipants.contains(uid);
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
                          })
                        else ...[
                          ...widget.roomGroup.memberIds
                              .where((uid) => uid != currentUserId)
                              .map((uid) {
                            return _CustomSplitTile(
                              userId: uid,
                              controller: _customControllers[uid]!,
                              onChanged: () => setState(() {}),
                            );
                          }),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tổng đã phân bổ:', style: AppTextStyles.caption),
                              Text(
                                FormatUtils.formatMoney(
                                  _calculateCustomTotal(currentUserId),
                                ),
                                style: AppTextStyles.caption.copyWith(
                                  color: (_parsedAmount > 0 &&
                                          (_calculateCustomTotal(currentUserId) -
                                                      _parsedAmount)
                                                  .abs() <=
                                              1)
                                      ? AppColors.success
                                      : AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (_parsedAmount > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Còn lại:', style: AppTextStyles.caption),
                                Text(
                                  FormatUtils.formatMoney(
                                    _parsedAmount -
                                        _calculateCustomTotal(currentUserId),
                                  ),
                                  style: AppTextStyles.caption.copyWith(
                                    color: (_parsedAmount -
                                                    _calculateCustomTotal(
                                                      currentUserId,
                                                    ))
                                                .abs() <=
                                            1
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(
                    label: _isEditing ? 'Lưu thay đổi' : 'Lưu khoản chi',
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
          Text(
            title,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CustomSplitTile extends StatelessWidget {
  final String userId;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _CustomSplitTile({
    required this.userId,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile>(
      stream: context.read<UserNameCache>().profileStream(userId),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? UserProfile.fallback;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AppAvatar(name: profile.name, avatarUrl: profile.avatarUrl, size: 36),
              const SizedBox(width: 12),
              Expanded(child: Text(profile.name, style: AppTextStyles.label)),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.textHint,
                      fontSize: 14,
                    ),
                    suffixText: 'đ',
                    filled: true,
                    fillColor: AppColors.inputFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    return StreamBuilder<UserProfile>(
      stream: context.read<UserNameCache>().profileStream(userId),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? UserProfile.fallback;
        return GestureDetector(
          onTap: () => onChanged(!isSelected),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                AppAvatar(name: profile.name, avatarUrl: profile.avatarUrl, size: 36),
                const SizedBox(width: 12),
                Expanded(child: Text(profile.name, style: AppTextStyles.label)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.inputBorder,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
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
