import 'package:flutter/material.dart';
import 'admin_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────
class SupportWebPage extends StatefulWidget {
  const SupportWebPage({super.key});

  @override
  State<SupportWebPage> createState() => _SupportWebPageState();
}

class _SupportWebPageState extends State<SupportWebPage> {
  int _tabIdx = 0; // 0=Tất cả vé, 1=Hàng đợi của tôi

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AS.pagePad + 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(tabIdx: _tabIdx, onTab: (i) => setState(() => _tabIdx = i)),
            const SizedBox(height: 32),
            _StatsRow(),
            const SizedBox(height: 32),
            _TicketList(),
            const SizedBox(height: 32),
            _BottomSection(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page Header
// ─────────────────────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  final int tabIdx;
  final ValueChanged<int> onTab;
  const _PageHeader({required this.tabIdx, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trung tâm Hỗ trợ', style: AT.pageTitle),
              const SizedBox(height: 8),
              Text(
                'Quản lý các thắc mắc của người dùng và giải quyết vé hỗ trợ để đảm bảo trải nghiệm tìm bạn ở chung liền mạch.',
                style: AT.bodyMD,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AC.surfaceLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _TabBtn(label: 'Tất cả vé',      active: tabIdx == 0, onTap: () => onTab(0)),
              _TabBtn(label: 'Hàng đợi của tôi', active: tabIdx == 1, onTap: () => onTab(1)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AC.surfaceLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: AT.nav.copyWith(
            color: active ? AC.primary : AC.slate500,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────
class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
  });
}

class _StatsRow extends StatelessWidget {
  static const _stats = <_StatItem>[
    _StatItem(label: 'Vé đang mở',      value: '24',   icon: Icons.confirmation_number_outlined, valueColor: AC.primary),
    _StatItem(label: 'Phản hồi TB',     value: '1.2g', icon: Icons.schedule_outlined,            valueColor: AC.onSurface),
    _StatItem(label: 'Chưa phân công',  value: '08',   icon: Icons.person_off_outlined,          valueColor: Color(0xFFA33200)),
    _StatItem(label: 'Hài lòng',        value: '98%',  icon: Icons.sentiment_very_satisfied_outlined, valueColor: AC.primaryContainer),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_stats.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < _stats.length - 1 ? 20 : 0),
            child: _StatCard(data: _stats[i]),
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatefulWidget {
  final _StatItem data;
  const _StatCard({required this.data});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.all(AS.cardPad),
        decoration: BoxDecoration(
          color: AC.surfaceLowest,
          borderRadius: BorderRadius.circular(AS.cardRadius),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.label, style: AT.bodyMD.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(d.value, style: AT.kpiValue.copyWith(color: d.valueColor, fontSize: 32)),
              ],
            ),
            Positioned(
              right: -16,
              bottom: -16,
              child: AnimatedScale(
                scale: _hovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(d.icon, size: 80, color: d.valueColor.withValues(alpha: 0.06)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ticket List
// ─────────────────────────────────────────────────────────────────────────────
enum _TicketPriority { high, medium, low }
enum _TicketStatus { open, pending, resolved }

class _TicketData {
  final Color iconBg;
  final Color iconFg;
  final IconData icon;
  final String category;
  final Color categoryColor;
  final String id;
  final String title;
  final String subtitle;
  final _TicketPriority priority;
  final String time;
  final _TicketStatus status;
  final bool dimmed;
  final IconData actionIcon;
  const _TicketData({
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.category,
    required this.categoryColor,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.time,
    required this.status,
    this.dimmed = false,
    this.actionIcon = Icons.reply,
  });
}

class _TicketList extends StatelessWidget {
  static const _tickets = <_TicketData>[
    _TicketData(
      iconBg: AC.primaryFixed,
      iconFg: AC.primary,
      icon: Icons.payments_outlined,
      category: 'THANH TOÁN',
      categoryColor: AC.primary,
      id: 'Vé #FL-9021',
      title: 'Sai lệch trong việc chia hóa đơn điện nước hàng tháng cho Căn hộ 4B',
      subtitle: 'Người dùng báo cáo rằng tính toán tiền điện tự động không tính cho nửa tháng...',
      priority: _TicketPriority.high,
      time: '2 phút trước',
      status: _TicketStatus.open,
    ),
    _TicketData(
      iconBg: Color(0xFFD5E3FC),
      iconFg: Color(0xFF515F74),
      icon: Icons.account_circle_outlined,
      category: 'HỒ SƠ',
      categoryColor: Color(0xFF57657A),
      id: 'Vé #FL-8944',
      title: 'Không thể cập nhật thông tin liên lạc khẩn cấp',
      subtitle: 'Thông báo lỗi hiện lên mỗi khi nhấn Lưu trong trang cài đặt hồ sơ...',
      priority: _TicketPriority.low,
      time: '45 phút trước',
      status: _TicketStatus.pending,
    ),
    _TicketData(
      iconBg: AC.primaryFixedDim,
      iconFg: Color(0xFF003FA4),
      icon: Icons.terminal_outlined,
      category: 'KỸ THUẬT',
      categoryColor: AC.primaryContainer,
      id: 'Vé #FL-8812',
      title: 'Ứng dụng di động bị treo khi khởi động trên iOS 17.4',
      subtitle: 'Nhật ký hiển thị lỗi con trỏ null khi khởi tạo màn hình chờ...',
      priority: _TicketPriority.medium,
      time: '2 giờ trước',
      status: _TicketStatus.open,
    ),
    _TicketData(
      iconBg: Color(0xFFECEEF0),
      iconFg: AC.onSurfaceVariant,
      icon: Icons.check_circle_outline,
      category: 'THANH TOÁN',
      categoryColor: AC.onSurfaceVariant,
      id: 'Vé #FL-8750',
      title: 'Yêu cầu hoàn tiền cho việc thanh toán trùng trong tháng 1',
      subtitle: 'Đã giải quyết: Tiền đã được hoàn vào số dư tài khoản và thông báo cho người dùng...',
      priority: _TicketPriority.low,
      time: '5 giờ trước',
      status: _TicketStatus.resolved,
      dimmed: true,
      actionIcon: Icons.visibility_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: AC.surfaceLowest,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              children: [
                Text('Yêu cầu hỗ trợ gần đây', style: AT.sectionTitle),
                const Spacer(),
                _TextIconBtn(icon: Icons.filter_list, label: 'Lọc'),
                const SizedBox(width: 16),
                _TextIconBtn(icon: Icons.sort, label: 'Sắp xếp'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECEEF0)),
          // Tickets
          ..._tickets.map((t) => _TicketRow(data: t)),
          // Pagination footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            color: AC.surfaceLow,
            child: Row(
              children: [
                Text('Hiển thị 4 trên 24 vé', style: AT.bodyMD.copyWith(fontWeight: FontWeight.w500)),
                const Spacer(),
                _PageIconBtn(icon: Icons.chevron_left),
                const SizedBox(width: 8),
                _PageIconBtn(icon: Icons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextIconBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  const _TextIconBtn({required this.icon, required this.label});

  @override
  State<_TextIconBtn> createState() => _TextIconBtnState();
}

class _TextIconBtnState extends State<_TextIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: Row(
          children: [
            Icon(widget.icon, size: 16, color: _hovered ? AC.primary : AC.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(widget.label,
                style: AT.cardLabel.copyWith(
                    color: _hovered ? AC.primary : AC.onSurfaceVariant,
                    fontSize: 11,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _PageIconBtn extends StatefulWidget {
  final IconData icon;
  const _PageIconBtn({required this.icon});

  @override
  State<_PageIconBtn> createState() => _PageIconBtnState();
}

class _PageIconBtnState extends State<_PageIconBtn> {
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AC.surfaceLowest,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
            ],
          ),
          child: Icon(widget.icon, size: 18, color: _hovered ? AC.primary : AC.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _TicketRow extends StatefulWidget {
  final _TicketData data;
  const _TicketRow({required this.data});

  @override
  State<_TicketRow> createState() => _TicketRowState();
}

class _TicketRowState extends State<_TicketRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered
            ? const Color(0xFFEFF6FF).withValues(alpha: 0.5)
            : AC.surfaceLowest,
        child: Opacity(
          opacity: t.dimmed ? 0.75 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: t.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(t.icon, size: 22, color: t.iconFg),
                ),
                const SizedBox(width: 24),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(t.category,
                              style: AT.cardLabel.copyWith(
                                  color: t.categoryColor, fontSize: 10)),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AC.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(t.id, style: AT.bodySM),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AT.nav.copyWith(fontSize: 14, color: AC.onSurface)),
                      const SizedBox(height: 2),
                      Text(t.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AT.bodyMD),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Priority
                SizedBox(
                  width: 96,
                  child: Column(
                    children: [
                      _PriorityBadge(priority: t.priority),
                      const SizedBox(height: 6),
                      Text(t.time, style: AT.bodyXS),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Status
                SizedBox(
                  width: 96,
                  child: _StatusBadge(status: t.status),
                ),
                const SizedBox(width: 16),
                // Reply button (show on hover)
                AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AC.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(t.actionIcon, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final _TicketPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (priority) {
      _TicketPriority.high   => (const Color(0xFFCC4204).withValues(alpha: 0.1), const Color(0xFFCC4204), 'ƯU TIÊN CAO'),
      _TicketPriority.medium => (const Color(0xFFFFEDD5), const Color(0xFFEA580C), 'TRUNG BÌNH'),
      _TicketPriority.low    => (AC.surfaceHighest, AC.onSurfaceVariant, 'ƯU TIÊN THẤP'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AT.cardLabel.copyWith(color: fg, fontSize: 9, letterSpacing: 0.5)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _TicketStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      _TicketStatus.open     => (const Color(0xFFDBEAFE), const Color(0xFF1D4ED8), 'MỞ'),
      _TicketStatus.pending  => (const Color(0xFFFFDBD0), const Color(0xFF832600), 'ĐANG CHỜ'),
      _TicketStatus.resolved => (const Color(0xFFD1FAE5), const Color(0xFF059669), 'ĐÃ GIẢI QUYẾT'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: AT.cardLabel.copyWith(color: fg, fontSize: 9, letterSpacing: 0.5)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Section
// ─────────────────────────────────────────────────────────────────────────────
class _BottomSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI suggestion card (flex 2)
        Expanded(flex: 2, child: _AiSuggestionCard()),
        const SizedBox(width: AS.gap),
        // Leaderboard card (flex 1)
        Expanded(flex: 1, child: _LeaderboardCard()),
      ],
    );
  }
}

class _AiSuggestionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AC.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AC.primary.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tối ưu hóa thời gian phản hồi', style: AT.sectionTitle.copyWith(fontSize: 22)),
                    const SizedBox(height: 12),
                    Text(
                      'Phân tích AI của chúng tôi cho thấy 40% vé Thanh toán có thể được giải quyết bằng hướng dẫn "Tranh chấp thanh toán" tự động. Bạn có muốn tạo mẫu không?',
                      style: AT.bodyMD,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AC.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: Text('Bật Mẫu tự động',
                          style: AT.nav.copyWith(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  color: AC.primaryFixedDim,
                  borderRadius: BorderRadius.circular(24),
                ),
                transform: Matrix4.rotationZ(0.21),
                child: const Icon(Icons.auto_awesome, size: 52, color: AC.primary),
              ),
            ],
          ),
          // Decorative orb
          Positioned(
            right: -64,
            top: -64,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AC.primary.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  static const _agents = <(String, String, int)>[
    ('AS', 'Alex Smith',  12),
    ('MJ', 'Maria Jones',  9),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.support_agent_outlined, size: 28, color: AC.primaryFixedDim),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('BẢNG XẾP HẠNG HỖ TRỢ',
                    style: AT.cardLabel.copyWith(color: AC.primaryFixedDim, fontSize: 9, letterSpacing: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._agents.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _agents.indexOf(a) == 0
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF6366F1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(a.$1,
                            style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(a.$2,
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                    ),
                    Text('${a.$3} Giải quyết',
                        style: AT.bodyMD.copyWith(
                            color: AC.primaryFixedDim, fontWeight: FontWeight.w700)),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('BÁO CÁO ĐẦY ĐỦ',
                  style: AT.cardLabel.copyWith(color: Colors.white, fontSize: 10, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }
}
