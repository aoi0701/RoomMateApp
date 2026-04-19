import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_tokens.dart';
import 'dashboard_web_page.dart';
import 'posts_web_page.dart';
import 'users_web_page.dart';
import 'support_web_page.dart';
import 'media_web_page.dart';
import 'criteria_web_page.dart';
import 'expenses_web_page.dart';
import 'violations_web_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell
// ─────────────────────────────────────────────────────────────────────────────
class AdminWebShell extends StatefulWidget {
  const AdminWebShell({super.key});

  @override
  State<AdminWebShell> createState() => _AdminWebShellState();
}

class _AdminWebShellState extends State<AdminWebShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.surface,
      body: Row(
        children: [
          _Sidebar(selectedIndex: _idx, onChanged: (i) => setState(() => _idx = i)),
          Expanded(
            child: Column(
              children: [
                const _Topbar(),
                Expanded(child: _page()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _Fab(),
    );
  }

  Widget _page() => switch (_idx) {
        0 => const DashboardWebPage(),
        1 => const UsersWebPage(),
        2 => const PostsWebPage(),
        4 => const ExpensesWebPage(),
        5 => const CriteriaWebPage(),
        6 => const MediaWebPage(),
        7 => const SupportWebPage(),
        8 => const ViolationsWebPage(),
        _ => Center(
            child: Text('Trang đang phát triển',
                style: AT.bodyMD.copyWith(color: AC.slate400))),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _Sidebar({required this.selectedIndex, required this.onChanged});

  static const _items = <(IconData, String)>[
    (Icons.dashboard_outlined,       'Bảng điều khiển'),
    (Icons.group_outlined,           'Người dùng'),
    (Icons.dynamic_feed_outlined,    'Bài đăng'),
    (Icons.hub_outlined,             'Nhóm'),
    (Icons.payments_outlined,        'Chi phí'),
    (Icons.rule_outlined,            'Tiêu chí'),
    (Icons.perm_media_outlined,      'Đa phương tiện'),
    (Icons.contact_support_outlined, 'Hỗ trợ'),
    (Icons.report_problem_outlined,  'Vi phạm'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AS.sidebarW,
      color: AC.slate50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RoomMate', style: AT.brand),
                const SizedBox(height: 4),
                Text('BẢNG QUẢN TRỊ',
                    style: AT.cardLabel.copyWith(fontSize: 10, letterSpacing: 1.5)),
              ],
            ),
          ),
          // Nav
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _items.length,
              itemBuilder: (_, i) => _NavItem(
                icon: _items[i].$1,
                label: _items[i].$2,
                isActive: selectedIndex == i,
                onTap: () => onChanged(i),
              ),
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Tạo mới',
                        style: AT.nav.copyWith(color: Colors.white)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AC.primaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AC.primaryFixed,
                      child: const Text('AD',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AC.blue700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quản trị viên',
                              style: AT.nav.copyWith(
                                  fontSize: 13, color: AC.onSurface)),
                          Text('Admin', style: AT.bodyXS),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, size: 18, color: AC.slate500),
                      tooltip: 'Đăng xuất',
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
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
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AC.slate100
                : _hovered
                    ? AC.slate200.withValues(alpha: 0.6)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.isActive
                ? const Border(
                    right: BorderSide(color: AC.blue600, width: 4))
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon,
                  size: 20,
                  color: widget.isActive ? AC.blue700 : AC.slate500),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: AT.nav.copyWith(
                  color: widget.isActive ? AC.blue700 : AC.slate500,
                  fontWeight: widget.isActive
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topbar
// ─────────────────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  const _Topbar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AS.topbarH,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  style: AT.bodySM.copyWith(color: AC.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Tìm kiếm cơ sở dữ liệu, người dùng hoặc nhật ký...',
                    hintStyle: AT.bodySM,
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AC.slate400),
                    filled: true,
                    fillColor: AC.slate50,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide:
                          const BorderSide(color: AC.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Icons
          _TopbarIconBtn(icon: Icons.notifications_outlined, tooltip: 'Thông báo'),
          const SizedBox(width: 4),
          _TopbarIconBtn(icon: Icons.settings_outlined, tooltip: 'Cài đặt'),
          const SizedBox(width: 16),
          const VerticalDivider(
              thickness: 1, indent: 12, endIndent: 12, color: AC.slate200),
          const SizedBox(width: 16),
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AC.primaryFixed,
            child: const Text('AR',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AC.blue700)),
          ),
        ],
      ),
    );
  }
}

class _TopbarIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  const _TopbarIconBtn({required this.icon, required this.tooltip});

  @override
  State<_TopbarIconBtn> createState() => _TopbarIconBtnState();
}

class _TopbarIconBtnState extends State<_TopbarIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: IconButton(
        icon: Icon(widget.icon, size: 22),
        color: _hovered ? AC.blue600 : AC.slate600,
        onPressed: () {},
        tooltip: widget.tooltip,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB
// ─────────────────────────────────────────────────────────────────────────────
class _Fab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AC.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 8,
        tooltip: 'Thao tác nhanh',
        child: const Icon(Icons.bolt, size: 28),
      ),
    );
  }
}
