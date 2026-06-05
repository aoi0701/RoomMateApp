import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../viewmodels/home_search_filter_viewmodel.dart';
import '../../data/models/room_search_filter_model.dart';

// Màn hình bộ lọc tìm phòng: chỉnh sửa draft filter rồi trả về kết quả khi apply
class RoomSearchFilterScreen extends StatefulWidget {
  final RoomSearchFilterModel initialFilter;

  const RoomSearchFilterScreen({
    super.key,
    required this.initialFilter,
  });

  @override
  State<RoomSearchFilterScreen> createState() => _RoomSearchFilterScreenState();
}

class _RoomSearchFilterScreenState extends State<RoomSearchFilterScreen> {
  late RoomSearchFilterModel _draft;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilter;
    _searchController = TextEditingController(text: _draft.keyword);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickSingleOption({
    required String title,
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _SelectionSheet(
        title: title,
        options: options,
        selectedValues: {selectedValue},
        multiSelect: false,
      ),
    );

    if (result != null) {
      onSelected(result);
    }
  }

  Future<void> _save() async {
    final success =
        await context.read<HomeSearchFilterViewModel>().saveFilter(_draft);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context, _draft);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<HomeSearchFilterViewModel>().errorMessage ??
                'Không thể lưu bộ lọc',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeSearchFilterViewModel>();
    final districts =
        RoomSearchFilterModel.districtsByProvince[_draft.province] ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lọc tìm phòng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _draft = _draft.copyWith(keyword: value);
                        });
                      },
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên phòng hoặc địa chỉ...',
                        hintStyle: AppTextStyles.body.copyWith(
                          color: AppColors.textHint,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.trim().isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _draft = _draft.copyWith(keyword: '');
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FilterField(
                      label: 'Tỉnh/Thành phố',
                      value: _draft.province.isEmpty
                          ? 'Chọn tỉnh/thành phố'
                          : _draft.province,
                      onTap: () => _pickSingleOption(
                        title: 'Chọn khu vực',
                        options: RoomSearchFilterModel.provinces,
                        selectedValue: _draft.province,
                        onSelected: (value) {
                          setState(() {
                            _draft = _draft.copyWith(
                              province: value,
                              district: '',
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FilterField(
                      label: 'Quận/huyện',
                      value: _draft.district.isEmpty
                          ? 'Chọn quận/huyện'
                          : _draft.district,
                      onTap: _draft.province.isEmpty
                          ? null
                          : () => _pickSingleOption(
                                title: 'Chọn quận/huyện',
                                options: districts,
                                selectedValue: _draft.district,
                                onSelected: (value) {
                                  setState(() {
                                    _draft = _draft.copyWith(district: value);
                                  });
                                },
                              ),
                    ),
                    const SizedBox(height: 20),
                    _FilterField(
                      label: 'Loại phòng',
                      value: _draft.roomType.isEmpty
                          ? 'Chọn loại phòng'
                          : _draft.roomType,
                      onTap: () => _pickSingleOption(
                        title: 'Chọn loại phòng',
                        options: RoomSearchFilterModel.roomTypes,
                        selectedValue: _draft.roomType,
                        onSelected: (value) {
                          setState(() {
                            _draft = _draft.copyWith(roomType: value);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(title: 'Giá', helper: '(bỏ chọn để xem tất cả)'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: RoomSearchFilterModel.priceRanges.map((item) {
                        final selected = _draft.priceRangeId == item.id;
                        return _SelectableChipBox(
                          label: item.label,
                          selected: selected,
                          onTap: () {
                            setState(() {
                              _draft = _draft.copyWith(
                                priceRangeId: selected ? '' : item.id,
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(
                      title: 'Tiện ích khác',
                      helper: '(bỏ chọn để xem tất cả)',
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children:
                          RoomSearchFilterModel.amenitiesCatalog.map((item) {
                        final selected = _draft.amenities.contains(item);
                        return _SelectableChipBox(
                          label: item,
                          selected: selected,
                          onTap: () {
                            final nextAmenities = [..._draft.amenities];
                            if (selected) {
                              nextAmenities.remove(item);
                            } else {
                              nextAmenities.add(item);
                            }
                            setState(() {
                              _draft = _draft.copyWith(amenities: nextAmenities);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: AppPrimaryButton(
                label: 'Áp dụng',
                isLoading: vm.isSaving,
                onTap: vm.isSaving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _FilterField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDisabled ? AppColors.inputBorder : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.body.copyWith(
                      color: isDisabled
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          top: -11,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSm.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String helper;

  const _SectionTitle({required this.title, required this.helper});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: title,
            style: AppTextStyles.h2,
          ),
          TextSpan(
            text: ' $helper',
            style: AppTextStyles.body.copyWith(color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}

class _SelectableChipBox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableChipBox({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 64) / 3;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
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
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final Set<String> selectedValues;
  final bool multiSelect;

  const _SelectionSheet({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.multiSelect,
  });

  @override
  State<_SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<_SelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _filtered;
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
    _selected = {...widget.selectedValues}..remove('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h2,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _filtered = widget.options
                        .where((item) =>
                            item.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  });
                },
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung tìm kiếm',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textHint,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final option = _filtered[index];
                    final selected = _selected.contains(option);
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: widget.multiSelect
                          ? Icon(
                              selected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            )
                          : null,
                      tileColor: selected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : null,
                      textColor: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      title: Text(option, style: AppTextStyles.body),
                      trailing: selected && !widget.multiSelect
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () {
                        if (!widget.multiSelect) {
                          Navigator.pop(context, selected ? '' : option);
                          return;
                        }
                        setState(() {
                          if (selected) {
                            _selected.remove(option);
                          } else {
                            _selected.add(option);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              AppPrimaryButton(
                label: 'Xác nhận',
                onTap: widget.multiSelect
                    ? () => Navigator.pop(context, _selected.toList())
                    : () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
