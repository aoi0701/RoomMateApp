import 'package:flutter/material.dart';
import 'admin_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class CriteriaWebPage extends StatefulWidget {
  const CriteriaWebPage({super.key});

  @override
  State<CriteriaWebPage> createState() => _CriteriaWebPageState();
}

class _CriteriaWebPageState extends State<CriteriaWebPage> {
  int _selectedIdx = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          Text('Tiêu chí Phù hợp',
              style: AT.pageTitle.copyWith(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Tinh chỉnh trọng số và bộ lọc cho thuật toán tìm kiếm người ở ghép.',
              style: AT.bodySM.copyWith(color: AC.onSurfaceVariant)),
          const SizedBox(height: 40),
          // Two-column layout
          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 900;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _CriteriaList(
                    selectedIdx: _selectedIdx,
                    onSelect: (i) => setState(() => _selectedIdx = i),
                  )),
                  const SizedBox(width: 32),
                  Expanded(flex: 5, child: _ConfigPanel(selectedIdx: _selectedIdx)),
                ],
              );
            }
            return Column(children: [
              _CriteriaList(
                selectedIdx: _selectedIdx,
                onSelect: (i) => setState(() => _selectedIdx = i),
              ),
              const SizedBox(height: 24),
              _ConfigPanel(selectedIdx: _selectedIdx),
            ]);
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────
class _CriterionData {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final List<String> tags;
  final int weight;

  const _CriterionData({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.weight,
  });
}

const _criteria = [
  _CriterionData(
    icon: Icons.payments_outlined,
    iconBg: Color(0xFFB3C5FF),
    iconFg: AC.primary,
    title: 'Khoảng ngân sách',
    subtitle: 'Ngưỡng tương thích về tài chính',
    tags: ['Quan trọng', 'Bắt buộc'],
    weight: 95,
  ),
  _CriterionData(
    icon: Icons.smoke_free,
    iconBg: Color(0xFFFFB59D),
    iconFg: Color(0xFFA33200),
    title: 'Tình trạng hút thuốc',
    subtitle: 'Lọc theo sở thích lối sống',
    tags: ['Khớp Nhị phân'],
    weight: 80,
  ),
  _CriterionData(
    icon: Icons.pets,
    iconBg: Color(0xFFB9C7DF),
    iconFg: Color(0xFF515F74),
    title: 'Thân thiện với thú cưng',
    subtitle: 'Sống chung với động vật',
    tags: ['Chọn nhiều'],
    weight: 70,
  ),
  _CriterionData(
    icon: Icons.cleaning_services_outlined,
    iconBg: AC.blue100,
    iconFg: AC.blue700,
    title: 'Mức độ sạch sẽ',
    subtitle: 'Kỳ vọng về bảo trì không gian chung',
    tags: ['Phổ điểm'],
    weight: 65,
  ),
  _CriterionData(
    icon: Icons.wc_outlined,
    iconBg: AC.slate200,
    iconFg: AC.slate600,
    title: 'Ưu tiên giới tính',
    subtitle: 'Ưu tiên về an ninh và sự thoải mái',
    tags: ['Cốt yếu'],
    weight: 100,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Criteria List
// ─────────────────────────────────────────────────────────────────────────────
class _CriteriaList extends StatelessWidget {
  final int selectedIdx;
  final ValueChanged<int> onSelect;

  const _CriteriaList({required this.selectedIdx, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Thông số Hoạt Động',
                style: AT.sectionTitle.copyWith(fontSize: 18)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AC.primaryFixed,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text('5 ĐANG HOẠT ĐỘNG',
                  style: AT.cardLabel.copyWith(fontSize: 10, letterSpacing: 1.2)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...List.generate(_criteria.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CriterionCard(
                data: _criteria[i],
                isSelected: selectedIdx == i,
                onTap: () => onSelect(i),
              ),
            )),
      ],
    );
  }
}

class _CriterionCard extends StatefulWidget {
  final _CriterionData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _CriterionCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CriterionCard> createState() => _CriterionCardState();
}

class _CriterionCardState extends State<_CriterionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AC.primary.withValues(alpha: 0.4)
                  : _hovered
                      ? AC.outlineVariant.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered || widget.isSelected ? 0.08 : 0.03),
                blurRadius: _hovered || widget.isSelected ? 16 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: d.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(d.icon, size: 28, color: d.iconFg),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title,
                        style: AT.bodyMD.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AC.onSurface)),
                    const SizedBox(height: 4),
                    Text(d.subtitle, style: AT.bodySM),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: d.tags.map((t) => _Tag(label: t)).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${d.weight}%',
                      style: AT.kpiValue.copyWith(
                          fontSize: 28, color: AC.primary, fontWeight: FontWeight.w900)),
                  Text('TRỌNG SỐ',
                      style: AT.bodyXS.copyWith(
                          letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  Color get _bg {
    if (label == 'Quan trọng' || label == 'Cốt yếu') return const Color(0xFFFFDBC8);
    return AC.surfaceHighest;
  }

  Color get _fg {
    if (label == 'Quan trọng' || label == 'Cốt yếu') return const Color(0xFF390C00);
    return AC.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: AT.bodyXS.copyWith(
              fontSize: 10, fontWeight: FontWeight.w700, color: _fg, letterSpacing: 0.5)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Config Panel
// ─────────────────────────────────────────────────────────────────────────────
class _ConfigPanel extends StatefulWidget {
  final int selectedIdx;
  const _ConfigPanel({required this.selectedIdx});

  @override
  State<_ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<_ConfigPanel> {
  double _weight = 0.95;
  int _enforcementIdx = 0;

  static const _algos = ['Phổ tài chính', 'Nhị phân Có/Không', 'Trọng số Ưu tiên'];

  int _algoIdx = 0;

  @override
  void didUpdateWidget(_ConfigPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIdx != widget.selectedIdx) {
      setState(() {
        _weight = _criteria[widget.selectedIdx].weight / 100.0;
        _algoIdx = 0;
        _enforcementIdx = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _criteria[widget.selectedIdx];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cấu hình Tiêu chí',
              style: AT.sectionTitle.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          // Label
          _FieldLabel('Nhãn hiển thị'),
          const SizedBox(height: 8),
          _TextField(value: d.title),
          const SizedBox(height: 20),
          // Icon + Algo row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Biểu tượng tham chiếu'),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AC.surfaceHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(d.icon, size: 20, color: AC.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(d.icon.codePoint.toRadixString(16),
                                style: AT.bodySM.copyWith(
                                    color: AC.onSurface, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Loại thuật toán'),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AC.surfaceHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _algoIdx,
                          isExpanded: true,
                          style: AT.bodySM.copyWith(
                              color: AC.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                          items: List.generate(_algos.length, (i) => DropdownMenuItem(
                                value: i,
                                child: Text(_algos[i]),
                              )),
                          onChanged: (v) => setState(() => _algoIdx = v!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Weight slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FieldLabel('Độ nhạy trọng số'),
              Text('${(_weight * 100).round()}%',
                  style: AT.bodySM.copyWith(
                      color: AC.primary, fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AC.primary,
              inactiveTrackColor: AC.surfaceHighest,
              thumbColor: AC.primary,
              overlayColor: AC.primary.withValues(alpha: 0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: _weight,
              onChanged: (v) => setState(() => _weight = v),
            ),
          ),
          Text(
            'Xác định mức độ ảnh hưởng của yếu tố này đến điểm số "% Phù hợp" cuối cùng.',
            style: AT.bodyXS.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),
          // Enforcement
          _FieldLabel('Mức độ thực thi'),
          const SizedBox(height: 12),
          _EnforcementOption(
            label: 'Lọc cứng (Phải khớp hoàn toàn)',
            selected: _enforcementIdx == 0,
            onTap: () => setState(() => _enforcementIdx = 0),
          ),
          const SizedBox(height: 8),
          _EnforcementOption(
            label: 'Khớp mềm (Điểm số có trọng số)',
            selected: _enforcementIdx == 1,
            onTap: () => setState(() => _enforcementIdx = 1),
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AC.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    shadowColor: AC.primary.withValues(alpha: 0.3),
                  ),
                  child: Text('Cập nhật Tiêu chí',
                      style: AT.bodySM.copyWith(
                          fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  side: BorderSide.none,
                  backgroundColor: AC.surfaceHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Hủy bỏ',
                    style: AT.bodySM.copyWith(
                        fontWeight: FontWeight.w700, color: AC.onSurface, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Algorithm preview mini-card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AC.primaryFixed.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AC.primaryFixed.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: AC.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('XEM TRƯỚC TÁC ĐỘNG',
                        style: AT.cardLabel.copyWith(
                            color: const Color(0xFF003FA4), letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Việc tăng trọng số này sẽ khiến các kết quả khớp có chênh lệch ngân sách trên 200\$ tự động bị giảm ưu tiên 15,4% trong nguồn cấp dữ liệu khám phá toàn cầu.',
                  style: AT.bodyXS.copyWith(color: AC.onSurfaceVariant, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: AT.cardLabel.copyWith(fontSize: 10, letterSpacing: 1.5));
  }
}

class _TextField extends StatelessWidget {
  final String value;
  const _TextField({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AC.surfaceHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(value,
          style: AT.bodySM.copyWith(color: AC.onSurface, fontWeight: FontWeight.w600)),
    );
  }
}

class _EnforcementOption extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EnforcementOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_EnforcementOption> createState() => _EnforcementOptionState();
}

class _EnforcementOptionState extends State<_EnforcementOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered || widget.selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: widget.selected ? AC.primary : AC.outlineVariant, width: 2),
                  color: widget.selected ? AC.primary : Colors.transparent,
                ),
                child: widget.selected
                    ? const Icon(Icons.circle, size: 8, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(widget.label,
                  style: AT.bodySM.copyWith(
                      fontWeight: FontWeight.w600, color: AC.onSurface, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
