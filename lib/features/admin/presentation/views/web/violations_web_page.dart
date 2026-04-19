import 'package:flutter/material.dart';
import 'admin_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class ViolationsWebPage extends StatefulWidget {
  const ViolationsWebPage({super.key});

  @override
  State<ViolationsWebPage> createState() => _ViolationsWebPageState();
}

class _ViolationsWebPageState extends State<ViolationsWebPage> {
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
          _ModerationTable(tabIdx: _tabIdx, onTab: (i) => setState(() => _tabIdx = i)),
          const SizedBox(height: 32),
          _FooterSection(),
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
              Text('Vi phạm & Báo cáo',
                  style: AT.pageTitle.copyWith(fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Hàng đợi thực thi và nhật ký hoạt động kiểm duyệt.',
                  style: AT.bodySM.copyWith(color: AC.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text('HÀNG ĐỢI HOẠT ĐỘNG',
                  style: AT.cardLabel.copyWith(fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AC.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('24 đang chờ',
                    style: AT.bodyXS.copyWith(
                        color: AC.onErrorContainer, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ],
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
          children: [
            Expanded(flex: 2, child: _UrgentCard()),
            const SizedBox(width: 24),
            Expanded(child: _MiniStat(
              icon: Icons.warning_amber_outlined,
              iconColor: const Color(0xFFA33200),
              badge: '+12% so với tuần trước',
              badgeColor: const Color(0xFF832600),
              label: 'Báo cáo hàng tuần',
              value: '142',
            )),
            const SizedBox(width: 24),
            Expanded(child: _MiniStat(
              icon: Icons.gavel_outlined,
              iconColor: AC.primary,
              badge: '98% đã phản hồi',
              badgeColor: AC.primary,
              label: 'Thời gian xử lý TB',
              value: '14p',
            )),
          ],
        );
      }
      return Column(children: [
        _UrgentCard(),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _MiniStat(
            icon: Icons.warning_amber_outlined,
            iconColor: const Color(0xFFA33200),
            badge: '+12%',
            badgeColor: const Color(0xFF832600),
            label: 'Báo cáo hàng tuần',
            value: '142',
          )),
          const SizedBox(width: 16),
          Expanded(child: _MiniStat(
            icon: Icons.gavel_outlined,
            iconColor: AC.primary,
            badge: '98%',
            badgeColor: AC.primary,
            label: 'Thời gian xử lý TB',
            value: '14p',
          )),
        ]),
      ]);
    });
  }
}

class _UrgentCard extends StatefulWidget {
  @override
  State<_UrgentCard> createState() => _UrgentCardState();
}

class _UrgentCardState extends State<_UrgentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AC.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TỔNG QUAN MỨC ĐỘ NGHIÊM TRỌNG',
                    style: AT.cardLabel.copyWith(
                        color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text('Ưu tiên khẩn cấp',
                    style: AT.kpiValue.copyWith(
                        fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 16),
                Text(
                  'Có 8 báo cáo về hành vi quấy rối cần can thiệp ngay lập tức để duy trì an toàn cộng đồng.',
                  style: AT.bodySM.copyWith(
                      color: Colors.white.withValues(alpha: 0.9), height: 1.6),
                ),
              ],
            ),
            Positioned(
              right: -16,
              bottom: -16,
              child: AnimatedScale(
                scale: _hovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 400),
                child: Transform(
                  transform: Matrix4.rotationZ(0.21),
                  alignment: Alignment.center,
                  child: const Icon(Icons.security, size: 96,
                      color: Color(0x1AFFFFFF)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String badge;
  final Color badgeColor;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.badge,
    required this.badgeColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AC.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 22, color: iconColor),
              Text(badge,
                  style: AT.bodyXS.copyWith(
                      color: badgeColor, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: AT.bodySM.copyWith(color: AC.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(value,
              style: AT.kpiValue.copyWith(
                  fontSize: 30, fontWeight: FontWeight.w900, color: AC.onSurface)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Moderation Table
// ─────────────────────────────────────────────────────────────────────────────
enum _ViolationType { fraud, harassment, inappropriate }

enum _ActionTaken { permanentBan, warning, ban3days }

class _ViolationRow {
  final bool isUser;
  final String name;
  final String detail;
  final _ViolationType type;
  final String reporter;
  final String reporterId;
  final bool systemReporter;
  final _ActionTaken action;
  final bool canEnforce;

  const _ViolationRow({
    required this.isUser,
    required this.name,
    required this.detail,
    required this.type,
    required this.reporter,
    required this.reporterId,
    this.systemReporter = false,
    required this.action,
    required this.canEnforce,
  });
}

const _violations = [
  _ViolationRow(
    isUser: true,
    name: '@crypto_king_99',
    detail: '"Thuê penthouse này chỉ với \$200! DM ngay..."',
    type: _ViolationType.fraud,
    reporter: 'Sarah Jenkins',
    reporterId: 'ID: 992834',
    action: _ActionTaken.permanentBan,
    canEnforce: true,
  ),
  _ViolationRow(
    isUser: false,
    name: 'Bài viết #882-C',
    detail: 'Bình luận: "Chẳng ai hỏi ý kiến của bạn cả..."',
    type: _ViolationType.harassment,
    reporter: 'Mike D.',
    reporterId: 'ID: 110293',
    action: _ActionTaken.warning,
    canEnforce: false,
  ),
  _ViolationRow(
    isUser: true,
    name: 'James Wilson',
    detail: 'Hình ảnh: Chia sẻ nội dung không phù hợp trong Chat nhóm',
    type: _ViolationType.inappropriate,
    reporter: 'Bot tự động #4',
    reporterId: 'Hệ thống gắn thẻ',
    systemReporter: true,
    action: _ActionTaken.ban3days,
    canEnforce: true,
  ),
];

class _ModerationTable extends StatelessWidget {
  final int tabIdx;
  final ValueChanged<int> onTab;

  const _ModerationTable({required this.tabIdx, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          // Table header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFECEEF0))),
            ),
            child: Row(
              children: [
                Text('Đang chờ thực thi',
                    style: AT.sectionTitle.copyWith(fontSize: 17)),
                const Spacer(),
                _FilterPills(
                  labels: const ['Tất cả báo cáo', 'Lừa đảo', 'Quấy rối'],
                  selectedIdx: tabIdx,
                  onTab: onTab,
                ),
              ],
            ),
          ),
          // Column headers
          Container(
            color: AC.surfaceLow,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 4, child: _ColHdr('Nội dung bị báo cáo')),
                Expanded(flex: 2, child: _ColHdr('Lý do')),
                Expanded(flex: 2, child: _ColHdr('Người báo cáo')),
                Expanded(flex: 2, child: _ColHdr('Hành động đã thực hiện', center: true)),
                Expanded(flex: 2, child: _ColHdr('Kiểm duyệt', right: true)),
              ],
            ),
          ),
          // Rows
          ..._violations.map((v) => _ViolationRowWidget(data: v)),
          // Load more
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AC.surfaceLow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('TẢI THÊM 120 BÁO CÁO',
                      style: AT.cardLabel.copyWith(
                          color: AC.primary, letterSpacing: 1.5)),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: AC.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColHdr extends StatelessWidget {
  final String text;
  final bool center;
  final bool right;
  const _ColHdr(this.text, {this.center = false, this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: center
            ? TextAlign.center
            : right
                ? TextAlign.right
                : TextAlign.left,
        style: AT.bodyXS.copyWith(
            fontWeight: FontWeight.w900, letterSpacing: 1.2,
            color: AC.onSurfaceVariant));
  }
}

class _FilterPills extends StatelessWidget {
  final List<String> labels;
  final int selectedIdx;
  final ValueChanged<int> onTab;

  const _FilterPills(
      {required this.labels, required this.selectedIdx, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final active = selectedIdx == i;
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => onTab(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AC.surfaceHighest : AC.surfaceLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(labels[i],
                  style: AT.bodyXS.copyWith(
                      fontWeight: FontWeight.w700,
                      color: active ? AC.onSurface : AC.onSurfaceVariant,
                      fontSize: 11)),
            ),
          ),
        );
      }),
    );
  }
}

class _ViolationRowWidget extends StatefulWidget {
  final _ViolationRow data;
  const _ViolationRowWidget({required this.data});

  @override
  State<_ViolationRowWidget> createState() => _ViolationRowWidgetState();
}

class _ViolationRowWidgetState extends State<_ViolationRowWidget> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hov ? AC.surfaceLow.withValues(alpha: 0.5) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Row(
            children: [
              // Content
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AC.surfaceHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: d.isUser
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Icon(Icons.person, size: 28, color: AC.slate400))
                          : const Icon(Icons.article_outlined,
                              size: 26, color: AC.slate400),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name,
                              style: AT.bodySM.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AC.onSurface,
                                  fontSize: 13)),
                          Text(d.detail,
                              style: AT.bodyXS.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AC.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Type badge
              Expanded(
                flex: 2,
                child: _TypeBadge(type: d.type),
              ),
              // Reporter
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.reporter,
                        style: AT.bodySM.copyWith(
                            fontWeight: FontWeight.w500, color: AC.onSurface)),
                    Text(d.reporterId,
                        style: AT.bodyXS.copyWith(
                            color: d.systemReporter ? AC.primary : AC.slate400,
                            fontWeight: d.systemReporter
                                ? FontWeight.w700
                                : FontWeight.w400)),
                  ],
                ),
              ),
              // Action taken
              Expanded(
                flex: 2,
                child: Center(child: _ActionLabel(action: d.action)),
              ),
              // Button
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _ActionButton(canEnforce: d.canEnforce),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final _ViolationType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (type) {
      _ViolationType.fraud         => (const Color(0xFFCC4204), const Color(0xFFFFF6F4), 'LỪA ĐẢO'),
      _ViolationType.harassment    => (AC.primaryFixed,          AC.onSurfaceVariant,    'QUẤY RỐI'),
      _ViolationType.inappropriate => (const Color(0xFFA33200), Colors.white,            'KHÔNG PHÙ HỢP'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.5)),
    );
  }
}

class _ActionLabel extends StatelessWidget {
  final _ActionTaken action;
  const _ActionLabel({required this.action});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (action) {
      _ActionTaken.permanentBan => (AC.onErrorContainer, 'Khóa vĩnh viễn'),
      _ActionTaken.warning      => (AC.onSurfaceVariant, 'Cảnh cáo'),
      _ActionTaken.ban3days     => (AC.onErrorContainer, 'Khóa 3 ngày'),
    };
    return Text(label,
        style: AT.bodyXS.copyWith(fontWeight: FontWeight.w700, color: color));
  }
}

class _ActionButton extends StatefulWidget {
  final bool canEnforce;
  const _ActionButton({required this.canEnforce});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedScale(
        scale: _hov && widget.canEnforce ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.canEnforce ? AC.primary : AC.surfaceHighest,
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.canEnforce
                ? [BoxShadow(
                    color: AC.primary.withValues(alpha: 0.25), blurRadius: 8)]
                : null,
          ),
          child: Text(
            widget.canEnforce ? 'Thực thi' : 'Xem xét',
            style: AT.bodyXS.copyWith(
                fontWeight: FontWeight.w700,
                color: widget.canEnforce ? Colors.white : AC.onSurface),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer Section
// ─────────────────────────────────────────────────────────────────────────────
class _FooterSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final wide = constraints.maxWidth > 700;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _ActivityLog()),
            const SizedBox(width: 24),
            Expanded(child: _CommunityHealth()),
          ],
        );
      }
      return Column(children: [
        _ActivityLog(),
        const SizedBox(height: 16),
        _CommunityHealth(),
      ]);
    });
  }
}

class _ActivityLog extends StatelessWidget {
  static const _logs = [
    (AC.primary,           'Admin đã áp dụng Khóa vĩnh viễn đối với người dùng @bot_account_12', '2 PHÚT TRƯỚC'),
    (AC.onSurfaceVariant,  'Hệ thống đã loại bỏ báo cáo #9921 (Trùng lặp)',                           '14 PHÚT TRƯỚC'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nhật ký hoạt động kiểm duyệt',
              style: AT.sectionTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ..._logs.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: e.$1, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.$2,
                              style: AT.bodySM.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AC.onSurface,
                                  fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(e.$3,
                              style: AT.bodyXS.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AC.onSurfaceVariant,
                                  letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _CommunityHealth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: AC.primaryFixed, shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_outlined,
                color: AC.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Sức khỏe cộng đồng',
              style: AT.sectionTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Tâm lý chung của cộng đồng đang ổn định. Tỷ lệ vi phạm giảm 4% so với mức trung bình 30 ngày.',
            textAlign: TextAlign.center,
            style: AT.bodySM.copyWith(color: AC.onSurfaceVariant, height: 1.6),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {},
            child: Text('XEM PHÂN TÍCH CHUYÊN SÂU',
                style: AT.cardLabel.copyWith(
                    color: AC.primary, letterSpacing: 1.5,
                    decoration: TextDecoration.underline,
                    decorationColor: AC.primary)),
          ),
        ],
      ),
    );
  }
}
