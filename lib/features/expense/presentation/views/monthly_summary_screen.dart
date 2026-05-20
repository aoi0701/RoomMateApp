import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/app_state_widgets.dart';
import '../../../profile/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../../room_group/data/models/room_group_model.dart';
import '../../data/models/expense_model.dart';
import '../viewmodels/expense_viewmodel.dart';

class MonthlySummaryScreen extends StatefulWidget {
  final RoomGroupModel roomGroup;

  const MonthlySummaryScreen({super.key, required this.roomGroup});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSummary();
    });
  }

  void _loadSummary() {
    context.read<ExpenseViewModel>().loadMonthlySummary(
          roomGroupId: widget.roomGroup.id,
          year: _year,
          month: _month,
        );
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
    _loadSummary();
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
    _loadSummary();
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thống kê chi tiêu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: Consumer<ExpenseViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoading) {
                  return const AppLoadingState(message: 'Đang tải...');
                }

                if (vm.errorMessage != null) {
                  return AppErrorState(
                    title: 'Lỗi',
                    message: vm.errorMessage!,
                    onRetry: _loadSummary,
                  );
                }

                if (vm.monthlyExpenses.isEmpty) {
                  return const AppEmptyState(
                    title: 'Không có dữ liệu',
                    message: 'Chưa có khoản chi nào trong tháng này.',
                    icon: Icons.bar_chart_rounded,
                  );
                }

                return _buildContent(vm);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _prevMonth,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Tháng $_month/$_year',
            style: AppTextStyles.labelLg,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _nextMonth,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ExpenseViewModel vm) {
    final spendMap = vm.spendByMember(widget.roomGroup.memberIds);
    final sortedMembers = widget.roomGroup.memberIds.toList()
      ..sort((a, b) => (spendMap[b] ?? 0).compareTo(spendMap[a] ?? 0));

    // Group expenses by date
    final Map<String, List<ExpenseModel>> grouped = {};
    for (final expense in vm.monthlyExpenses) {
      final key = expense.createdAt != null
          ? _formatDate(expense.createdAt!)
          : 'Không rõ ngày';
      grouped.putIfAbsent(key, () => []).add(expense);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Total card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x305B6AF0),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tháng $_month/$_year',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tổng chi: ${FormatUtils.formatMoney(vm.monthlyTotal)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                '${vm.monthlyExpenses.length} khoản chi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Member breakdown
        _buildSectionTitle('Chi tiêu theo thành viên'),
        const SizedBox(height: 12),
        Container(
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
            children: sortedMembers.asMap().entries.map((entry) {
              final idx = entry.key;
              final uid = entry.value;
              final amount = spendMap[uid] ?? 0;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: _UserNameWidget(userId: uid),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          FormatUtils.formatMoney(amount),
                          style: AppTextStyles.labelLg.copyWith(
                            color: amount > 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (idx < sortedMembers.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Expenses grouped by date
        _buildSectionTitle('Chi tiết theo ngày'),
        const SizedBox(height: 12),
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  entry.key,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...entry.value.map((expense) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            expense.title,
                            style: AppTextStyles.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          FormatUtils.formatMoney(expense.amount),
                          style: AppTextStyles.labelLg.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.h2);
  }
}

class _UserNameWidget extends StatelessWidget {
  final String userId;
  const _UserNameWidget({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: context.read<UserProfileViewModel>().getUserProfileStream(userId),
      builder: (context, snapshot) {
        String name = 'Người dùng';
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!.data()?['fullName'] ?? 'Người dùng';
        }
        return Text(
          name,
          style: AppTextStyles.label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );
      },
    );
  }
}
