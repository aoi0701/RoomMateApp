import 'package:flutter/material.dart';
import 'admin_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class ExpensesWebPage extends StatefulWidget {
  const ExpensesWebPage({super.key});

  @override
  State<ExpensesWebPage> createState() => _ExpensesWebPageState();
}

class _ExpensesWebPageState extends State<ExpensesWebPage> {
  int _tabIdx = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(),
          const SizedBox(height: 32),
          _StatsGrid(),
          const SizedBox(height: 32),
          _LedgerTable(tabIdx: _tabIdx, onTab: (i) => setState(() => _tabIdx = i)),
          const SizedBox(height: 32),
          _BottomSection(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quản lý Chi tiêu',
                  style: AT.pageTitle.copyWith(fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Tổng quan sổ cái thời gian thực cho quản gia hiện đại.',
                  style: AT.bodySM.copyWith(color: AC.slate500)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _HeaderBtn(
          icon: Icons.file_download_outlined,
          label: 'Xuất CSV',
          outlined: true,
        ),
        const SizedBox(width: 12),
        _HeaderBtn(
          icon: Icons.warning_amber_outlined,
          label: 'Giải quyết Tranh chấp',
          outlined: false,
        ),
      ],
    );
  }
}

class _HeaderBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool outlined;
  const _HeaderBtn({required this.icon, required this.label, required this.outlined});

  @override
  State<_HeaderBtn> createState() => _HeaderBtnState();
}

class _HeaderBtnState extends State<_HeaderBtn> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: widget.outlined
              ? (_hov ? AC.surfaceHighest : Colors.transparent)
              : AC.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.outlined
              ? null
              : [BoxShadow(color: AC.primary.withValues(alpha: 0.25), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 18,
                color: widget.outlined ? AC.primary : Colors.white),
            const SizedBox(width: 8),
            Text(widget.label,
                style: AT.bodySM.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.outlined ? AC.primary : Colors.white,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid
// ─────────────────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final wide = constraints.maxWidth > 700;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 8, child: _TotalCard()),
            const SizedBox(width: 24),
            Expanded(flex: 4, child: _DisputeCard()),
          ],
        );
      }
      return Column(children: [
        _TotalCard(),
        const SizedBox(height: 16),
        _DisputeCard(),
      ]);
    });
  }
}

class _TotalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TỔNG THANH TOÁN ĐÃ XỬ LÝ',
                  style: AT.cardLabel.copyWith(fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '142.850.000',
                      style: AT.kpiValue.copyWith(
                          fontSize: 48, fontWeight: FontWeight.w900, color: AC.onSurface),
                    ),
                    TextSpan(
                      text: ' đ',
                      style: AT.kpiValue.copyWith(
                          fontSize: 24, color: AC.slate400, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.trending_up, size: 20, color: Color(0xFF059669)),
                  const SizedBox(width: 6),
                  Text('+12.5% so với tháng trước',
                      style: AT.bodySM.copyWith(
                          color: const Color(0xFF059669), fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: -16,
            right: -16,
            child: Icon(Icons.account_balance_wallet,
                size: 96, color: AC.primary.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFCC4204),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TRANH CHẤP CHƯA GIẢI QUYẾT',
                  style: AT.cardLabel.copyWith(
                      fontSize: 11, letterSpacing: 1.5, color: Colors.white.withValues(alpha: 0.8))),
              const SizedBox(height: 16),
              Text('14',
                  style: AT.kpiValue.copyWith(
                      fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Yêu cầu xử lý khẩn cấp',
                      style:
                          AT.bodySM.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.priority_high, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: -8,
            top: -8,
            child: Icon(Icons.gavel_outlined,
                size: 100, color: Colors.white.withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ledger Table
// ─────────────────────────────────────────────────────────────────────────────
enum _ExpenseStatus { settled, disputed, partial, pending }

class _ExpenseRow {
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String name;
  final String subtitle;
  final String amount;
  final String splitType;
  final _ExpenseStatus status;

  const _ExpenseRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.splitType,
    required this.status,
  });
}

const _rows = [
  _ExpenseRow(
    icon: Icons.apartment_outlined,
    iconBg: Color(0xFFDBEAFE),
    iconFg: AC.primary,
    name: 'Căn hộ Skyline 4B',
    subtitle: '4 Người tham gia',
    amount: '2.450.000 đ',
    splitType: 'Chia đều',
    status: _ExpenseStatus.settled,
  ),
  _ExpenseRow(
    icon: Icons.bolt_outlined,
    iconBg: Color(0xFFFFEDD5),
    iconFg: Color(0xFFEA580C),
    name: 'Điện nước tháng 9',
    subtitle: 'Dịch vụ dùng chung',
    amount: '412.150 đ',
    splitType: 'Phần trăm %',
    status: _ExpenseStatus.disputed,
  ),
  _ExpenseRow(
    icon: Icons.shopping_cart_outlined,
    iconBg: Color(0xFFF3E8FF),
    iconFg: Color(0xFF9333EA),
    name: 'Cải tạo Nhà bếp',
    subtitle: 'Mua sắm nhóm',
    amount: '5.800.000 đ',
    splitType: 'Tùy chỉnh',
    status: _ExpenseStatus.partial,
  ),
  _ExpenseRow(
    icon: Icons.wifi_outlined,
    iconBg: Color(0xFFDBEAFE),
    iconFg: AC.primary,
    name: 'Internet Cáp quang',
    subtitle: 'Cố định hàng tháng',
    amount: '89.990 đ',
    splitType: 'Chia đều',
    status: _ExpenseStatus.pending,
  ),
];

class _LedgerTable extends StatelessWidget {
  final int tabIdx;
  final ValueChanged<int> onTab;

  const _LedgerTable({required this.tabIdx, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text('Sổ cái Chung đang hoạt động',
                    style: AT.sectionTitle.copyWith(fontSize: 17)),
                const Spacer(),
                _TabPill(labels: const ['Tất cả chi phí', 'Đang chờ', 'Bị gắn cờ'],
                    selectedIdx: tabIdx, onTab: onTab),
              ],
            ),
          ),
          // Column headers
          Container(
            color: AC.surfaceLow.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 4, child: _ColHeader('Tên Nhóm')),
                Expanded(flex: 2, child: _ColHeader('Tổng số tiền', right: true)),
                Expanded(flex: 2, child: _ColHeader('Cách chia')),
                Expanded(flex: 3, child: _ColHeader('Trạng thái')),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Rows
          ..._rows.map((r) => _ExpenseRowWidget(data: r)),
          // Pagination
          _Pagination(),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final bool right;
  const _ColHeader(this.text, {this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: AT.bodyXS.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AC.slate400));
  }
}

class _TabPill extends StatelessWidget {
  final List<String> labels;
  final int selectedIdx;
  final ValueChanged<int> onTab;

  const _TabPill(
      {required this.labels, required this.selectedIdx, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AC.surfaceHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = selectedIdx == i;
          return GestureDetector(
            onTap: () => onTab(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: active
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 4)]
                    : null,
              ),
              child: Text(
                labels[i],
                style: AT.bodySM.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? AC.primary : AC.slate500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ExpenseRowWidget extends StatefulWidget {
  final _ExpenseRow data;
  const _ExpenseRowWidget({required this.data});

  @override
  State<_ExpenseRowWidget> createState() => _ExpenseRowWidgetState();
}

class _ExpenseRowWidgetState extends State<_ExpenseRowWidget> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hov ? AC.slate50 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Row(
            children: [
              // Name
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: d.iconBg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(d.icon, size: 20, color: d.iconFg),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name,
                            style: AT.bodyMD.copyWith(
                                fontWeight: FontWeight.w700, color: AC.onSurface)),
                        Text(d.subtitle,
                            style:
                                AT.bodyXS.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Expanded(
                flex: 2,
                child: Text(d.amount,
                    textAlign: TextAlign.right,
                    style: AT.bodyMD.copyWith(
                        fontWeight: FontWeight.w900, color: AC.onSurface)),
              ),
              // Split
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AC.surfaceHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(d.splitType,
                        style: AT.bodyXS.copyWith(
                            fontWeight: FontWeight.w600, color: AC.slate600)),
                  ),
                ),
              ),
              // Status
              Expanded(flex: 3, child: _StatusWidget(status: d.status)),
              // Action
              SizedBox(width: 48, child: _ActionWidget(status: d.status)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusWidget extends StatelessWidget {
  final _ExpenseStatus status;
  const _StatusWidget({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _ExpenseStatus.settled => Row(children: [
          Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Đã tất toán',
              style: AT.bodySM.copyWith(fontWeight: FontWeight.w700, color: AC.onSurface)),
        ]),
      _ExpenseStatus.disputed => Row(children: [
          Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFFA33200), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Tranh chấp (2)',
              style: AT.bodySM.copyWith(
                  fontWeight: FontWeight.w700, color: const Color(0xFFA33200))),
        ]),
      _ExpenseStatus.partial => Row(
          children: [
            Stack(children: [
              Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                  child: Center(child: Text('3', style: AT.bodyXS.copyWith(color: Colors.white, fontWeight: FontWeight.w700)))),
              Positioned(
                left: 14,
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: AC.slate200, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: Center(child: Text('2', style: AT.bodyXS.copyWith(color: AC.slate600, fontWeight: FontWeight.w700))),
                ),
              ),
            ]),
            const SizedBox(width: 20),
            Text('3/5 Đã đóng',
                style: AT.bodySM.copyWith(fontWeight: FontWeight.w700, color: AC.onSurface)),
          ],
        ),
      _ExpenseStatus.pending => Row(children: [
          Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFFEAB308), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('Chờ xác minh',
              style: AT.bodySM.copyWith(fontWeight: FontWeight.w700, color: AC.onSurface)),
        ]),
    };
  }
}

class _ActionWidget extends StatefulWidget {
  final _ExpenseStatus status;
  const _ActionWidget({required this.status});

  @override
  State<_ActionWidget> createState() => _ActionWidgetState();
}

class _ActionWidgetState extends State<_ActionWidget> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    if (widget.status == _ExpenseStatus.disputed) {
      return GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFA33200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Giải quyết',
              style: AT.bodyXS.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _hov ? AC.surfaceHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          widget.status == _ExpenseStatus.pending ? Icons.history : Icons.chevron_right,
          size: 20,
          color: AC.slate400,
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AC.surfaceLow.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Text('Hiển thị 4 trên 128 giao dịch được ghi nhận',
              style: AT.bodySM.copyWith(color: AC.slate500, fontWeight: FontWeight.w500)),
          const Spacer(),
          _PageBtn(icon: Icons.navigate_before, onTap: () {}),
          const SizedBox(width: 8),
          _PageNum(label: '1', active: true),
          const SizedBox(width: 4),
          _PageNum(label: '2', active: false),
          const SizedBox(width: 8),
          _PageBtn(icon: Icons.navigate_next, onTap: () {}),
        ],
      ),
    );
  }
}

class _PageBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PageBtn({required this.icon, required this.onTap});

  @override
  State<_PageBtn> createState() => _PageBtnState();
}

class _PageBtnState extends State<_PageBtn> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hov ? AC.surfaceHighest : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AC.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Icon(widget.icon, size: 20, color: AC.slate400),
        ),
      ),
    );
  }
}

class _PageNum extends StatelessWidget {
  final String label;
  final bool active;
  const _PageNum({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? AC.primary : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: active ? null : Border.all(color: AC.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(label,
            style: AT.bodySM.copyWith(
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AC.slate600)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Section
// ─────────────────────────────────────────────────────────────────────────────
class _BottomSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final wide = constraints.maxWidth > 700;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ActivityFeed()),
            const SizedBox(width: 24),
            Expanded(child: _SplitDistribution()),
          ],
        );
      }
      return Column(children: [
        _ActivityFeed(),
        const SizedBox(height: 16),
        _SplitDistribution(),
      ]);
    });
  }
}

class _ActivityFeed extends StatelessWidget {
  static const _events = [
    (true,  Icons.check_circle_outline, Color(0xFFD1FAE5), Color(0xFF059669),
     'Alex Chen đã đóng 612.500 đ', 'Căn hộ Skyline 4B • 2 giờ trước'),
    (false, Icons.report_outlined,      AC.errorContainer, AC.onErrorContainer,
     'Tranh chấp mới được gửi', 'Điện nước tháng 9 (Jordan Smith) • 5 giờ trước'),
    (true,  Icons.history,              Color(0xFFDBEAFE), AC.blue600,
     'Tự động tất toán thành công', 'Hóa đơn Internet • Hôm qua lúc 11:45 CH'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lịch sử Thanh toán',
              style: AT.sectionTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          ..._events.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final isLast = i == _events.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: e.$3, shape: BoxShape.circle),
                      child: Icon(e.$2, size: 20, color: e.$4),
                    ),
                    if (!isLast)
                      Container(
                        width: 1,
                        height: 40,
                        color: AC.slate200,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.$5,
                            style: AT.bodySM.copyWith(
                                fontWeight: FontWeight.w700, color: AC.onSurface, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(e.$6, style: AT.bodyXS),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SplitDistribution extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phân bổ cách chia',
                    style: AT.sectionTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Phân tích ưu tiên hệ thống',
                    style: AT.bodyXS.copyWith(color: AC.slate400)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Donut chart placeholder
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: 0.64,
                    strokeWidth: 24,
                    backgroundColor: AC.primaryFixed,
                    valueColor: const AlwaysStoppedAnimation(AC.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('64%',
                        style: AT.kpiValue.copyWith(
                            fontSize: 28, fontWeight: FontWeight.w900, color: AC.onSurface)),
                    Text('CHIA ĐỀU',
                        style: AT.bodyXS.copyWith(
                            fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: AC.primary, label: 'Đều'),
              const SizedBox(width: 24),
              _Legend(color: AC.primaryFixed, label: 'Thủ công'),
              const SizedBox(width: 24),
              _Legend(color: const Color(0xFFCC4204), label: 'Phần trăm'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: AT.bodyXS.copyWith(fontWeight: FontWeight.w700, color: AC.slate600)),
      ],
    );
  }
}
