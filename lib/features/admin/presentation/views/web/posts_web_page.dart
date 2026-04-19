import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../post/data/models/post_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import 'admin_tokens.dart';

String _fmtPrice(int price) {
  if (price == 0) return '—';
  if (price >= 1000000) {
    final m = price / 1000000;
    return '${m % 1 == 0 ? m.toInt() : m.toStringAsFixed(1)}tr/th';
  }
  return '${price}đ/th';
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────
class PostsWebPage extends StatefulWidget {
  const PostsWebPage({super.key});

  @override
  State<PostsWebPage> createState() => _PostsWebPageState();
}

class _PostsWebPageState extends State<PostsWebPage> {
  // 0 = Bài viết, 1 = Nhóm
  int _tabIdx = 0;

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
            const SizedBox(height: 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: post list (flex 7)
                Expanded(
                  flex: 7,
                  child: _PostsPanel(tabIdx: _tabIdx),
                ),
                const SizedBox(width: AS.gap + 8),
                // Right: groups panel (flex 5)
                Expanded(
                  flex: 5,
                  child: _GroupsPanel(),
                ),
              ],
            ),
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
              Text('Kiểm duyệt nội dung', style: AT.pageTitle),
              const SizedBox(height: 8),
              Text(
                'Quản lý các tin đăng tìm người ở ghép và các nhóm cộng đồng riêng tư trong mạng lưới.',
                style: AT.bodyMD,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFECEEF0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _TabBtn(label: 'Bài viết', active: tabIdx == 0, onTap: () => onTab(0)),
              _TabBtn(label: 'Nhóm',    active: tabIdx == 1, onTap: () => onTab(1)),
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
// Posts Panel
// ─────────────────────────────────────────────────────────────────────────────
class _PostsPanel extends StatelessWidget {
  final int tabIdx;
  const _PostsPanel({required this.tabIdx});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    return StreamBuilder<List<PostModel>>(
      stream: vm.postsStream,
      builder: (context, snap) {
        final posts = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Tin đăng phòng', style: AT.sectionTitle),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AC.primaryFixed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    snap.hasData ? '${posts.length} BÀI ĐĂNG' : '...',
                    style: AT.cardLabel.copyWith(
                        fontSize: 10, color: AC.blue700, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!snap.hasData)
              const Center(child: CircularProgressIndicator())
            else if (posts.isEmpty)
              const Center(child: Text('Không có bài đăng nào.'))
            else
              ...posts.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PostCard(post: p),
                  )),
          ],
        );
      },
    );
  }
}

class _PostCard extends StatefulWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AS.cardPad),
        decoration: BoxDecoration(
          color: _hovered ? AC.surfaceLowest : AC.surfaceLowest,
          borderRadius: BorderRadius.circular(AS.cardRadius),
          border: Border.all(
            color: _hovered
                ? AC.primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.06 : 0.03),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: AC.surfaceLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_outlined,
                      size: 40, color: AC.slate400),
                ),
                Positioned(
                  top: -8,
                  left: -8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AC.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _fmtPrice(widget.post.price),
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.post.title.isNotEmpty ? widget.post.title : '(Không có tiêu đề)',
                                style: AT.sectionTitle.copyWith(fontSize: 16)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: AC.slate500),
                                const SizedBox(width: 4),
                                Text(widget.post.location.isNotEmpty ? widget.post.location : widget.post.province, style: AT.bodyMD),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Owner chip
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AC.primaryFixed,
                            child: Text(
                              '#',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AC.blue700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(widget.post.ownerId.length >= 6 ? widget.post.ownerId.substring(0, 6) : widget.post.ownerId, style: AT.bodySM),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      _ActionBtn(
                        label: 'Duyệt',
                        icon: Icons.check_circle_outline,
                        bg: AC.primaryContainer,
                        fg: const Color(0xFFF8F7FF),
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        label: 'Gắn thẻ',
                        icon: Icons.flag_outlined,
                        bg: const Color(0xFFCC4204),
                        fg: const Color(0xFFFFF6F4),
                      ),
                      const SizedBox(width: 8),
                      _DeleteBtn(postId: widget.post.id),
                    ],
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

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.bg,
      required this.fg});

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.bg.withValues(alpha: 0.85)
                : widget.bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: widget.fg),
              const SizedBox(width: 4),
              Text(widget.label,
                  style: AT.cardLabel.copyWith(
                      color: widget.fg, fontSize: 12, letterSpacing: 0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteBtn extends StatefulWidget {
  final String postId;
  const _DeleteBtn({required this.postId});
  @override
  State<_DeleteBtn> createState() => _DeleteBtnState();
}

class _DeleteBtnState extends State<_DeleteBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.read<AdminViewModel>().deletePost(widget.postId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? AC.errorContainer : const Color(0xFFE6E8EA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.delete_outline,
                  size: 14,
                  color: _hovered ? AC.onErrorContainer : AC.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Xóa',
                  style: AT.cardLabel.copyWith(
                      color: _hovered
                          ? AC.onErrorContainer
                          : AC.onSurfaceVariant,
                      fontSize: 12,
                      letterSpacing: 0)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Groups Panel
// ─────────────────────────────────────────────────────────────────────────────
class _GroupsPanel extends StatelessWidget {
  static const _groups = <_GroupData>[
    _GroupData(
      name: 'The Loft Collective',
      members: 4,
      months: 12,
      iconBg: Color(0xFFB3C5FF),
      iconColor: AC.primary,
      icon: Icons.group_work_outlined,
      disputed: false,
    ),
    _GroupData(
      name: 'Downtown Trio',
      members: 3,
      months: 6,
      iconBg: Color(0xFFFFB59D),
      iconColor: Color(0xFFA33200),
      icon: Icons.house_outlined,
      disputed: true,
    ),
    _GroupData(
      name: 'Uptown Creatives',
      members: 5,
      months: 24,
      iconBg: Color(0xFFD5E3FC),
      iconColor: Color(0xFF515F74),
      icon: Icons.apartment_outlined,
      disputed: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nhóm đang hoạt động', style: AT.sectionTitle),
            TextButton.icon(
              onPressed: () {},
              icon: Text('Xem tất cả',
                  style: AT.nav.copyWith(color: AC.primary, fontSize: 13)),
              label: const Icon(Icons.arrow_forward,
                  size: 14, color: AC.primary),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AC.surfaceLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: _groups
                .map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _GroupCard(data: g),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: AS.gap),
        // Stats card
        _StatsCard(),
      ],
    );
  }
}

class _GroupData {
  final String name;
  final int members;
  final int months;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final bool disputed;
  const _GroupData({
    required this.name,
    required this.members,
    required this.months,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.disputed,
  });
}

class _GroupCard extends StatefulWidget {
  final _GroupData data;
  const _GroupCard({required this.data});

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AC.surfaceLowest,
          borderRadius: BorderRadius.circular(12),
          border: d.disputed
              ? const Border(left: BorderSide(color: Color(0xFFA33200), width: 4))
              : null,
          boxShadow: _hovered
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: d.iconBg, shape: BoxShape.circle),
              child: Icon(d.icon, size: 22, color: d.iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name,
                      style: AT.nav.copyWith(
                          fontSize: 14, color: AC.onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.group_outlined,
                          size: 12, color: AC.slate500),
                      const SizedBox(width: 4),
                      Text('${d.members} Thành viên',
                          style: AT.bodyXS),
                      const SizedBox(width: 12),
                      const Icon(Icons.schedule_outlined,
                          size: 12, color: AC.slate500),
                      const SizedBox(width: 4),
                      Text('${d.months} Tháng',
                          style: AT.bodyXS),
                    ],
                  ),
                ],
              ),
            ),
            if (d.disputed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB59D).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_outlined,
                        size: 12, color: Color(0xFFA33200)),
                    const SizedBox(width: 4),
                    Text('Tranh chấp',
                        style: AT.bodyXS
                            .copyWith(color: const Color(0xFFA33200), fontWeight: FontWeight.w700)),
                  ],
                ),
              )
            else
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: AC.slate400),
                  onPressed: () {},
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AC.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TĂNG TRƯỞNG NỀN TẢNG',
                style: AT.cardLabel.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 8),
              const Text('+12.4%',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1)),
              const SizedBox(height: 16),
              Text(
                'Số cặp ghép nhóm thành công trong tháng này trên tất cả các khu vực.',
                style: AT.bodyMD.copyWith(
                    color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(Icons.trending_up,
                size: 120,
                color: Colors.white.withValues(alpha: 0.1)),
          ),
        ],
      ),
    );
  }
}
