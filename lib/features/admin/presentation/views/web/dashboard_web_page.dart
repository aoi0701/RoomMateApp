import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../admin/presentation/viewmodels/admin_viewmodel.dart';
import 'admin_tokens.dart';

class DashboardWebPage extends StatelessWidget {
  const DashboardWebPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AS.pagePad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PageHeader(),
          SizedBox(height: 40),
          _KpiGrid(),
          SizedBox(height: AS.gap),
          _BottomSection(),
          SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page Header
// ─────────────────────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tổng quan hệ thống', style: AT.pageTitle),
        const SizedBox(height: 8),
        Text(
          'Số liệu hiệu suất thời gian thực và sức khỏe hệ sinh thái.',
          style: AT.bodyMD,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI Grid (4 cards)
// ─────────────────────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  const _KpiGrid();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: vm.usersCountStream,
            builder: (_, snap) => _KpiCard(
              icon: Icons.group_outlined,
              label: 'Tổng người dùng',
              value: snap.hasData ? snap.data!.toString() : '...',
              valueColor: AC.primary,
              badge: _TrendBadge(label: 'Dữ liệu thực', positive: true),
            ),
          ),
        ),
        const SizedBox(width: AS.gap),
        Expanded(
          child: StreamBuilder<int>(
            stream: vm.postsCountStream,
            builder: (_, snap) => _KpiCard(
              icon: Icons.dynamic_feed_outlined,
              label: 'Tổng bài đăng',
              value: snap.hasData ? snap.data!.toString() : '...',
              valueColor: AC.primary,
              badge: Text('Tất cả bài đăng',
                  style: AT.bodyXS.copyWith(fontWeight: FontWeight.w500)),
            ),
          ),
        ),
        const SizedBox(width: AS.gap),
        Expanded(
          child: StreamBuilder<int>(
            stream: vm.requestsCountStream,
            builder: (_, snap) => _KpiCard(
              icon: Icons.hub_outlined,
              label: 'Yêu cầu ghép nhóm',
              value: snap.hasData ? snap.data!.toString() : '...',
              valueColor: AC.primary,
              badge: _InfoBadge(
                  label: 'Tất cả yêu cầu', bg: AC.blue50, fg: AC.blue600),
            ),
          ),
        ),
        const SizedBox(width: AS.gap),
        Expanded(
          child: StreamBuilder<int>(
            stream: vm.bannedCountStream,
            builder: (_, snap) => _KpiCard(
              icon: Icons.report_problem_outlined,
              label: 'Người dùng bị khóa',
              value: snap.hasData ? snap.data!.toString() : '...',
              bg: AC.errorContainer,
              valueColor: AC.onErrorContainer,
              labelColor: AC.onErrorContainer.withValues(alpha: 0.6),
              iconColor: AC.onErrorContainer,
              badge: _InfoBadge(
                label: 'Ưu tiên: Cao',
                bg: Colors.white.withValues(alpha: 0.4),
                fg: AC.onErrorContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final Color bg;
  final Color? labelColor;
  final Color? iconColor;
  final Widget? badge;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.bg = AC.surfaceLowest,
    this.labelColor,
    this.iconColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AS.cardPad),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AS.cardRadius),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Ghost icon background
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(icon,
                size: 80,
                color: (iconColor ?? AC.onSurface).withValues(alpha: 0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AT.cardLabel.copyWith(
                    color: labelColor ?? AC.slate500),
              ),
              const SizedBox(height: 8),
              Text(value,
                  style:
                      AT.kpiValue.copyWith(color: valueColor)),
              const SizedBox(height: 16),
              if (badge case final b?) b,
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final String label;
  final bool positive;
  const _TrendBadge({required this.label, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive ? AC.emerald600 : AC.onErrorContainer;
    final bg = positive ? AC.emerald50 : AC.errorContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              positive ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _InfoBadge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Section: Chart (2/3) + Right column (1/3)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomSection extends StatelessWidget {
  const _BottomSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(flex: 2, child: _WeeklyChartCard()),
        SizedBox(width: AS.gap),
        Expanded(
          child: Column(
            children: [
              _QuickActionsCard(),
              SizedBox(height: AS.gap),
              _RecentActivityCard(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Chart Card
// ─────────────────────────────────────────────────────────────────────────────
class _WeeklyChartCard extends StatefulWidget {
  const _WeeklyChartCard();

  @override
  State<_WeeklyChartCard> createState() => _WeeklyChartCardState();
}

class _WeeklyChartCardState extends State<_WeeklyChartCard> {
  int _rangeIdx = 0;
  static const _ranges = ['7N', '30N', '6T'];
  static const _heights = [0.40, 0.65, 0.55, 0.85, 0.75, 0.95, 0.60];
  static const _labels = ['Th2', 'Th3', 'Th4', 'Th5', 'Th6', 'Th7', 'CN'];
  static const _tips = ['4.2k', '5.1k', '4.6k', '7.3k', '6.5k', '8.1k', '5.0k'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(AS.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Người dùng hoạt động hàng tuần', style: AT.sectionTitle),
              Row(
                children: List.generate(_ranges.length, (i) {
                  final active = i == _rangeIdx;
                  return GestureDetector(
                    onTap: () => setState(() => _rangeIdx = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? AC.surfaceLowest : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: active
                            ? Border.all(
                                color: AC.outlineVariant.withValues(alpha: 0.4))
                            : null,
                      ),
                      child: Text(
                        _ranges[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: active ? AC.onSurface : AC.slate400,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 220,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_heights.length, (i) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _Bar(
                            heightFraction: _heights[i],
                            tooltip: '${_tips[i]} Người dùng',
                            highlighted: i == 5,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    _labels.length,
                    (i) => Expanded(
                      child: Center(
                        child: Text(_labels[i],
                            style: AT.bodyXS.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  final double heightFraction;
  final String tooltip;
  final bool highlighted;

  const _Bar({
    required this.heightFraction,
    required this.tooltip,
    required this.highlighted,
  });

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || widget.highlighted;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: FractionallySizedBox(
          heightFactor: widget.heightFraction,
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: active ? AC.primaryContainer : AC.primaryFixedDim,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Card
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AS.cardPad),
      decoration: BoxDecoration(
        color: AC.surfaceHighest,
        borderRadius: BorderRadius.circular(AS.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THAO TÁC NHANH',
              style: AT.cardLabel.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _ActionBtn(
            icon: Icons.fact_check_outlined,
            label: 'Duyệt bài đăng chờ',
            badge: '24',
          ),
          const SizedBox(height: 8),
          _ActionBtn(
            icon: Icons.verified_user_outlined,
            label: 'Xác minh người dùng mới',
          ),
          const SizedBox(height: 8),
          _ActionBtn(
            icon: Icons.mail_outlined,
            label: 'Gửi thông báo chung',
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? badge;
  const _ActionBtn({required this.icon, required this.label, this.badge});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? AC.primaryFixed : AC.surfaceLowest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: AC.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.label,
                    style: AT.nav.copyWith(
                        fontSize: 13, color: AC.onSurface)),
              ),
              if (widget.badge case final b?)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AC.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(b,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Card
// ─────────────────────────────────────────────────────────────────────────────
class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  static const _items = <(Color, Color, IconData, String, String, String)>[
    (AC.blue100, AC.blue600, Icons.person_add_outlined,
        'Đăng ký mới',
        "Sarah Jenkins đã tham gia nhóm 'Downtown Loft'",
        '2 phút trước'),
    (AC.orange100, AC.orange600, Icons.warning_amber_outlined,
        'Báo cáo vi phạm',
        "Nội dung không phù hợp trong 'Roommate Search'",
        '14 phút trước'),
    (AC.emerald100, AC.emerald600, Icons.payments_outlined,
        'Tất toán hàng loạt',
        "Đã thanh toán hóa đơn tiện ích cho 'Evergreen Apts'",
        '42 phút trước'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AS.cardPad),
      decoration: BoxDecoration(
        color: AC.surfaceLowest,
        borderRadius: BorderRadius.circular(AS.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOẠT ĐỘNG GẦN ĐÂY',
              style: AT.cardLabel.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 24),
          ..._items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: e.$1, shape: BoxShape.circle),
                      child: Icon(e.$3, size: 16, color: e.$2),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.$4,
                              style: AT.nav.copyWith(
                                  fontSize: 12, color: AC.onSurface)),
                          const SizedBox(height: 2),
                          Text(e.$5, style: AT.bodySM),
                          const SizedBox(height: 4),
                          Text(e.$6, style: AT.bodyXS),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AC.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Xem tất cả nhật ký',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
