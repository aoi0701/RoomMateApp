import 'package:flutter/material.dart';
import 'admin_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class MediaWebPage extends StatefulWidget {
  const MediaWebPage({super.key});

  @override
  State<MediaWebPage> createState() => _MediaWebPageState();
}

class _MediaWebPageState extends State<MediaWebPage> {
  int _tabIdx = 0;

  static const _tabs = ['Tất cả', 'Chờ phê duyệt', 'Đã gắn cờ', 'Đã phê duyệt'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(tabIdx: _tabIdx, tabs: _tabs, onTab: (i) => setState(() => _tabIdx = i)),
          const SizedBox(height: 32),
          _MediaGrid(),
          const SizedBox(height: 64),
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
  final int tabIdx;
  final List<String> tabs;
  final ValueChanged<int> onTab;

  const _PageHeader({required this.tabIdx, required this.tabs, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quản lý nội dung',
                  style: AT.pageTitle.copyWith(fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Xem xét và kiểm duyệt nội dung được tải lên bởi người tìm phòng và chủ nhà.',
                style: AT.bodySM.copyWith(color: AC.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        _TabBar(tabIdx: tabIdx, tabs: tabs, onTab: onTab),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  final int tabIdx;
  final List<String> tabs;
  final ValueChanged<int> onTab;

  const _TabBar({required this.tabIdx, required this.tabs, required this.onTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = tabIdx == i;
          return GestureDetector(
            onTap: () => onTab(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(50),
                boxShadow: active
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
                    : null,
              ),
              child: Text(
                tabs[i],
                style: AT.bodySM.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? AC.primary : AC.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Media status & data
// ─────────────────────────────────────────────────────────────────────────────
enum _MediaStatus { pending, flagged, approved }

class _MediaItem {
  final String label;
  final String uploader;
  final String uploadTime;
  final _MediaStatus status;
  final String? flagReason;

  const _MediaItem({
    required this.label,
    required this.uploader,
    required this.uploadTime,
    required this.status,
    this.flagReason,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Media Grid
// ─────────────────────────────────────────────────────────────────────────────
class _MediaGrid extends StatelessWidget {
  static const _items = [
    _MediaItem(label: 'Xem trước phòng', uploader: 'Elena Rodriguez', uploadTime: 'Đã tải lên 2 giờ trước',  status: _MediaStatus.pending),
    _MediaItem(label: 'Nội dung Video',  uploader: 'Julian Weber',    uploadTime: 'Đã tải lên 5 giờ trước',  status: _MediaStatus.flagged, flagReason: 'Bị gắn cờ: Chất lượng thấp / Nhòe'),
    _MediaItem(label: 'Ảnh Đại diện',   uploader: 'Alex Thompson',   uploadTime: 'Đã tải lên 1 ngày trước', status: _MediaStatus.approved),
    _MediaItem(label: 'Khu vực chung',  uploader: 'Sarah Jenkins',   uploadTime: 'Đã tải lên 4 giờ trước',  status: _MediaStatus.pending),
    _MediaItem(label: 'Xem trước phòng',uploader: 'Markus Aurelius', uploadTime: 'Đã tải lên 2 ngày trước', status: _MediaStatus.approved),
    _MediaItem(label: 'Cảnh quan',      uploader: 'Claire Danes',    uploadTime: 'Đã tải lên 6 giờ trước',  status: _MediaStatus.pending),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final cols = w > 1400 ? 4 : w > 900 ? 3 : w > 600 ? 2 : 1;
      return Wrap(
        spacing: 24,
        runSpacing: 24,
        children: _items.map((item) {
          final cardW = (w - 24 * (cols - 1)) / cols;
          return SizedBox(width: cardW, child: _MediaCard(item: item));
        }).toList(),
      );
    });
  }
}

class _MediaCard extends StatefulWidget {
  final _MediaItem item;
  const _MediaCard({required this.item});

  @override
  State<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<_MediaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.12 : 0.04),
              blurRadius: _hovered ? 20 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardImage(item: widget.item, hovered: _hovered),
              _CardBody(item: widget.item),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final _MediaItem item;
  final bool hovered;
  const _CardImage({required this.item, required this.hovered});

  Color _imageBg(_MediaStatus s) => switch (s) {
        _MediaStatus.pending  => const Color(0xFF6B9FDB),
        _MediaStatus.flagged  => const Color(0xFF4A5568),
        _MediaStatus.approved => const Color(0xFF7CB9A8),
      };

  IconData _imageIcon(_MediaStatus s) => switch (s) {
        _MediaStatus.pending  => Icons.photo_outlined,
        _MediaStatus.flagged  => Icons.videocam_outlined,
        _MediaStatus.approved => Icons.person_outline,
      };

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: _imageBg(item.status),
            child: Center(
              child: Icon(_imageIcon(item.status), size: 64,
                  color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
          // Label badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: item.status == _MediaStatus.flagged
                    ? const Color(0xFFBA1A1A)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: item.status == _MediaStatus.flagged
                      ? Colors.white
                      : AC.primaryContainer,
                ),
              ),
            ),
          ),
          // Hover overlay
          AnimatedOpacity(
            opacity: hovered ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              color: item.status == _MediaStatus.approved
                  ? AC.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: item.status == _MediaStatus.approved
                    ? const Icon(Icons.verified_user, color: Colors.white, size: 40)
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                          item.status == _MediaStatus.flagged
                              ? Icons.play_arrow
                              : Icons.zoom_in,
                          color: AC.primary,
                          size: 28,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final _MediaItem item;
  const _CardBody({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AC.surfaceHighest,
                child: Icon(Icons.person, size: 16, color: AC.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.uploader,
                      style: AT.bodySM.copyWith(fontWeight: FontWeight.w700, color: AC.onSurface)),
                  Text(item.uploadTime, style: AT.bodyXS),
                ],
              ),
            ],
          ),
          if (item.flagReason != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.warning_outlined, size: 14, color: Color(0xFFBA1A1A)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(item.flagReason!,
                      style: AT.bodyXS.copyWith(
                          color: const Color(0xFFBA1A1A), fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFECEEF0)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CardActions(status: item.status),
              _StatusBadge(status: item.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  final _MediaStatus status;
  const _CardActions({required this.status});

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _MediaStatus.pending => Row(children: [
          _ActionBtn(icon: Icons.close, bg: AC.errorContainer, fg: AC.onErrorContainer),
          const SizedBox(width: 8),
          _ActionBtn(icon: Icons.check, bg: AC.primaryFixed, fg: AC.primary),
        ]),
      _MediaStatus.flagged => Row(children: [
          _ActionBtn(icon: Icons.delete_outline, bg: const Color(0xFFBA1A1A), fg: Colors.white),
          const SizedBox(width: 8),
          _ActionBtn(icon: Icons.info_outline, bg: AC.surfaceHighest, fg: AC.onSurfaceVariant),
        ]),
      _MediaStatus.approved => Row(children: [
          _ActionBtn(icon: Icons.undo, bg: AC.surfaceHighest, fg: AC.onErrorContainer),
        ]),
    };
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  const _ActionBtn({required this.icon, required this.bg, required this.fg});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: AnimatedOpacity(
        opacity: _hov ? 0.75 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: widget.bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(widget.icon, size: 18, color: widget.fg),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _MediaStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label, IconData? icon) = switch (status) {
      _MediaStatus.pending  => (const Color(0xFFFFDBC8), const Color(0xFFCC4204), 'ĐANG CHỜ',  Icons.pending_outlined),
      _MediaStatus.flagged  => (AC.errorContainer,       AC.onErrorContainer,     'BỊ GẮN CỜ', null),
      _MediaStatus.approved => (AC.primaryContainer,     Colors.white,            'ĐÃ DUYỆT',  Icons.check_circle),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.5)),
        ],
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
      final wide = constraints.maxWidth > 900;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _ModerationSummary()),
            const SizedBox(width: 24),
            Expanded(child: _QuickActions()),
          ],
        );
      }
      return Column(children: [
        _ModerationSummary(),
        const SizedBox(height: 16),
        _QuickActions(),
      ]);
    });
  }
}

class _ModerationSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final wide = constraints.maxWidth > 500;
        return wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: _SummaryText()),
                const SizedBox(width: 32),
                _AiFilterCard(),
              ])
            : Column(children: [_SummaryText(), const SizedBox(height: 24), _AiFilterCard()]);
      }),
    );
  }
}

class _SummaryText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nhịp độ kiểm duyệt',
            style: AT.sectionTitle.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: AT.bodySM.copyWith(color: AC.onSurfaceVariant, height: 1.6),
            children: [
              const TextSpan(text: 'Hoạt động hệ thống hiện tại đang '),
              TextSpan(
                  text: 'ổn định',
                  style: AT.bodySM.copyWith(color: AC.primary, fontWeight: FontWeight.w700)),
              const TextSpan(
                  text: '. Có 24 hình ảnh trong hàng đợi cần xem xét thủ công. '
                      'Nội dung bị gắn cờ đã giảm 12% so với tuần trước.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatMini(label: 'Hàng đợi', value: '24', color: AC.primary),
            const SizedBox(width: 16),
            _StatMini(label: 'Cờ báo', value: '03', color: AC.onErrorContainer),
            const SizedBox(width: 16),
            _StatMini(label: 'Tổng cộng', value: '1.2k', color: AC.onSurface),
          ],
        ),
      ],
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatMini({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AT.cardLabel.copyWith(fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(value,
              style: AT.kpiValue.copyWith(fontSize: 28, color: color)),
        ],
      ),
    );
  }
}

class _AiFilterCard extends StatefulWidget {
  @override
  State<_AiFilterCard> createState() => _AiFilterCardState();
}

class _AiFilterCardState extends State<_AiFilterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: 256,
        height: 192,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AC.primary, AC.primaryContainer],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              top: -16,
              child: AnimatedScale(
                scale: _hovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 400),
                child: Transform(
                  transform: Matrix4.rotationZ(0.21),
                  alignment: Alignment.center,
                  child: const Icon(Icons.security_update_good,
                      size: 120, color: Color(0x1AFFFFFF)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('BỘ LỌC TỰ ĐỘNG',
                      style: AT.bodyXS.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text('Quét nội dung AI đang hoạt động',
                      style: AT.bodySM.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.8,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BulkApproveCard(),
        const SizedBox(height: 16),
        _ReviewHistoryCard(),
      ],
    );
  }
}

class _BulkApproveCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AC.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_fix_high, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Công cụ duyệt nhanh',
                  style: AT.bodySM.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Phê duyệt tất cả các mục đa phương tiện đang chờ mà đã vượt qua kiểm tra tin cậy AI ban đầu (95%+).',
            style: AT.bodyXS.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AC.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Thực hiện duyệt hàng loạt',
                  style: AT.bodySM.copyWith(fontWeight: FontWeight.w700, color: AC.primary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewHistoryCard extends StatelessWidget {
  static const _events = [
    (true,  'Đã duyệt 12 ảnh phòng',             '10ph trước'),
    (false, 'Đã từ chối video "Living_Tour.mp4"', '22ph trước'),
    (true,  'Đã duyệt 5 ảnh đại diện',            '1g trước'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AC.surfaceHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lịch sử xem xét',
              style: AT.bodySM.copyWith(fontWeight: FontWeight.w700, color: AC.onSurface)),
          const SizedBox(height: 16),
          ..._events.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: e.$1 ? AC.primary : AC.onErrorContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.$2,
                          style: AT.bodyXS.copyWith(
                              color: AC.onSurfaceVariant, fontWeight: FontWeight.w500)),
                    ),
                    Text(e.$3, style: AT.bodyXS.copyWith(color: AC.slate400, fontSize: 10)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
