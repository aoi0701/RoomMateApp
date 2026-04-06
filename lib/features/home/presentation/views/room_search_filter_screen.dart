import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_search_filter_viewmodel.dart';
import '../../data/models/room_search_filter_model.dart';

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
  static const Color primaryBlue = Color(0xFF1E66F5);

  late RoomSearchFilterModel _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialFilter;
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
      backgroundColor: Colors.white,
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
    final districts = RoomSearchFilterModel.districtsByProvince[_draft.province] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'LỌC TÌM PHÒNG',
          style: TextStyle(fontWeight: FontWeight.w800),
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
                    _FilterField(
                      label: 'Tỉnh/Thành phố',
                      value: _draft.province.isEmpty ? 'Chọn tỉnh/thành phố' : _draft.province,
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
                    const SizedBox(height: 18),
                    _FilterField(
                      label: 'Quận/huyện',
                      value: _draft.district.isEmpty ? 'Chọn quận/huyện' : _draft.district,
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
                    const SizedBox(height: 18),
                    _FilterField(
                      label: 'Loại phòng',
                      value: _draft.roomType.isEmpty ? 'Chọn loại phòng' : _draft.roomType,
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
                    _SectionTitle(
                      title: 'Giá',
                      helper: '(bỏ chọn để xem tất cả)',
                    ),
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
                      children: RoomSearchFilterModel.amenitiesCatalog.map((item) {
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
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: vm.isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: vm.isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Áp dụng',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF9CA3AF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      color: onTap == null
                          ? const Color(0xFFB0B7C3)
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  color: RoomSearchFilterScreenStateColors.primaryBlue,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: -12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: RoomSearchFilterScreenStateColors.primaryBlue,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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

  const _SectionTitle({
    required this.title,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          TextSpan(
            text: ' $helper',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.red,
            ),
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
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF1E66F5) : const Color(0xFFE5E7EB),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? const Color(0xFF1E66F5) : const Color(0xFF4B5563),
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
                width: 64,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF4B5563),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 30),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _filtered = widget.options
                        .where((item) => item.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung tìm kiếm',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = _filtered[index];
                    final selected = _selected.contains(option);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      leading: widget.multiSelect
                          ? Icon(
                              selected
                                  ? Icons.check_box_outlined
                                  : Icons.check_box_outline_blank,
                            )
                          : null,
                      tileColor: selected ? const Color(0xFF1E66F5) : null,
                      textColor: selected ? Colors.white : const Color(0xFF111827),
                      title: Text(option),
                      onTap: () {
                        if (!widget.multiSelect) {
                          Navigator.pop(context, option);
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
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.multiSelect
                      ? () => Navigator.pop(context, _selected.toList())
                      : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E66F5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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

class RoomSearchFilterScreenStateColors {
  static const Color primaryBlue = Color(0xFF1E66F5);
}
