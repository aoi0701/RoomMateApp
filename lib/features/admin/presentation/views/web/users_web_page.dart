import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../features/admin/presentation/viewmodels/admin_viewmodel.dart';
import '../../../../../features/profile/data/models/user_model.dart';
import 'admin_tokens.dart';

String _fmtDate(DateTime? dt) {
  if (dt == null) return '—';
  const m = ['Th1','Th2','Th3','Th4','Th5','Th6','Th7','Th8','Th9','Th10','Th11','Th12'];
  return '${dt.day} ${m[dt.month - 1]}, ${dt.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────
class UsersWebPage extends StatefulWidget {
  const UsersWebPage({super.key});

  @override
  State<UsersWebPage> createState() => _UsersWebPageState();
}

class _UsersWebPageState extends State<UsersWebPage> {
  // 0=Tất cả 1=Hoạt động 2=Ngoại tuyến 3=Đã khóa
  int _filterIdx = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AS.pagePad + 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeader(),
            const SizedBox(height: 32),
            _StatsGrid(),
            const SizedBox(height: 32),
            _TableControls(
                filterIdx: _filterIdx,
                onFilter: (i) => setState(() => _filterIdx = i)),
            const SizedBox(height: 16),
            _UserTable(),
            const SizedBox(height: 48),
            _SecurityBanner(),
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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quản lý người dùng', style: AT.pageTitle),
        const SizedBox(height: 6),
        Text(
          'Quản lý và giám sát tất cả những người tham gia trong hệ sinh thái kinh tế chia sẻ.',
          style: AT.bodyMD,
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
    final vm = context.read<AdminViewModel>();
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<int>(
            stream: vm.usersCountStream,
            builder: (_, snap) => _StatCardWidget(data: _StatCard(
              label: 'TỔNG NGƯỜI DÙNG',
              value: snap.hasData ? snap.data!.toString() : '...',
              icon: Icons.group_outlined,
              bg: AC.surfaceLowest,
              valueFg: AC.onSurface,
              labelFg: AC.onSurfaceVariant,
              iconFg: AC.primary,
            )),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _StatCardWidget(data: const _StatCard(
            label: 'ĐANG HOẠT ĐỘNG',
            value: '—',
            icon: Icons.bolt,
            bg: AC.primaryFixed,
            valueFg: Color(0xFF001849),
            labelFg: Color(0xFF001849),
            iconFg: Color(0xFF003FA4),
          )),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _StatCardWidget(data: const _StatCard(
            label: 'ĐANG CHỜ XÁC MINH',
            value: '—',
            icon: Icons.verified_user_outlined,
            bg: AC.surfaceLowest,
            valueFg: AC.onSurface,
            labelFg: AC.onSurfaceVariant,
            iconFg: AC.primary,
          )),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: StreamBuilder<int>(
            stream: vm.bannedCountStream,
            builder: (_, snap) => _StatCardWidget(data: _StatCard(
              label: 'ĐÃ BỊ KHÓA',
              value: snap.hasData ? snap.data!.toString() : '...',
              icon: Icons.block_outlined,
              bg: AC.errorContainer,
              valueFg: AC.onErrorContainer,
              labelFg: AC.onErrorContainer,
              iconFg: AC.onErrorContainer,
            )),
          ),
        ),
      ],
    );
  }
}

class _StatCard {
  final String label;
  final String value;
  final IconData icon;
  final Color bg;
  final Color valueFg;
  final Color labelFg;
  final Color iconFg;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bg,
    required this.valueFg,
    required this.labelFg,
    required this.iconFg,
  });
}

class _StatCardWidget extends StatefulWidget {
  final _StatCard data;
  const _StatCardWidget({required this.data});

  @override
  State<_StatCardWidget> createState() => _StatCardWidgetState();
}

class _StatCardWidgetState extends State<_StatCardWidget> {
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
          color: d.bg,
          borderRadius: BorderRadius.circular(AS.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.label,
                    style: AT.cardLabel.copyWith(
                        color: d.labelFg, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(d.value,
                    style: AT.kpiValue.copyWith(
                        color: d.valueFg, fontSize: 32)),
              ],
            ),
            Positioned(
              right: -16,
              bottom: -16,
              child: AnimatedRotation(
                turns: _hovered ? 1 / 30 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(d.icon,
                    size: 80,
                    color: d.iconFg.withValues(alpha: _hovered ? 0.12 : 0.06)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Controls
// ─────────────────────────────────────────────────────────────────────────────
class _TableControls extends StatelessWidget {
  final int filterIdx;
  final ValueChanged<int> onFilter;
  const _TableControls({required this.filterIdx, required this.onFilter});

  static const _filters = ['Tất cả', 'Hoạt Động', 'Ngoại tuyến', 'Đã khóa'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AC.surfaceLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: AT.bodyMD.copyWith(color: AC.onSurface),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, email hoặc ID...',
                  hintStyle: AT.bodyMD,
                  prefixIcon: const Icon(Icons.person_search_outlined,
                      size: 20, color: AC.slate400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filter pills
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AC.surfaceLowest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
              ],
            ),
            child: Row(
              children: List.generate(
                _filters.length,
                (i) => _FilterPill(
                  label: _filters[i],
                  active: filterIdx == i,
                  onTap: () => onFilter(i),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _OutlineBtn(icon: Icons.filter_list, label: 'Bộ lọc'),
          const SizedBox(width: 8),
          _OutlineBtn(icon: Icons.download_outlined, label: 'Xuất dữ liệu'),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterPill(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AC.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AT.nav.copyWith(
            fontSize: 13,
            color: active ? Colors.white : AC.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  const _OutlineBtn({required this.icon, required this.label});

  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFE6E8EA) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AC.outlineVariant.withValues(alpha: 0.5), width: 1),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: AC.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(widget.label,
                  style:
                      AT.bodyMD.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Table
// ─────────────────────────────────────────────────────────────────────────────
enum _UserStatus { active, locked }

class _UserTable extends StatelessWidget {
  static const _headers = [
    'ID', 'Hồ sơ người dùng', 'Email', 'Ngày tham gia', 'Trạng thái', 'Thao tác'
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    return StreamBuilder<List<UserModel>>(
      stream: vm.usersStream,
      builder: (_, snap) {
        final users = snap.data ?? [];
        return Container(
          decoration: BoxDecoration(
            color: AC.surfaceLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: AC.surfaceLow,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    SizedBox(width: 72, child: _HeaderCell(_headers[0])),
                    Expanded(flex: 3, child: _HeaderCell(_headers[1])),
                    Expanded(flex: 3, child: _HeaderCell(_headers[2])),
                    Expanded(flex: 2, child: _HeaderCell(_headers[3])),
                    Expanded(flex: 2, child: _HeaderCell(_headers[4])),
                    SizedBox(
                        width: 120,
                        child: _HeaderCell(_headers[5], align: TextAlign.right)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFECEEF0)),
              if (!snap.hasData)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else if (users.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Không có người dùng nào.', style: AT.bodyMD),
                )
              else
                ...users.map((u) => _UserRow(user: u, vm: vm)),
              _PaginationFooter(count: users.length),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HeaderCell(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: AT.cardLabel.copyWith(fontSize: 11, letterSpacing: 0.8),
    );
  }
}

class _UserRow extends StatefulWidget {
  final UserModel user;
  final AdminViewModel vm;
  const _UserRow({required this.user, required this.vm});

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final isBanned = u.role == 'banned';
    final status = isBanned ? _UserStatus.locked : _UserStatus.active;
    final initials = u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?';
    final shortId = '#${u.uid.substring(0, 4).toUpperCase()}';
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? AC.surfaceLow.withValues(alpha: 0.5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E8EA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(shortId,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AC.onSurfaceVariant)),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AC.primaryFixed,
                    child: Text(initials,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AC.blue700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.fullName.isNotEmpty ? u.fullName : '(Chưa có tên)',
                            style: AT.nav.copyWith(fontSize: 14, color: AC.onSurface)),
                        const SizedBox(height: 2),
                        Text(u.role == 'admin' ? 'Quản trị viên' : 'Người dùng',
                            style: AT.bodyXS.copyWith(color: AC.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 3, child: Text(u.email, style: AT.bodyMD)),
            Expanded(flex: 2, child: Text(_fmtDate(u.createdAt), style: AT.bodyMD)),
            Expanded(flex: 2, child: _StatusBadge(status: status)),
            SizedBox(
              width: 120,
              child: _RowActions(uid: u.uid, status: status, vm: widget.vm),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _UserStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      _UserStatus.active => (const Color(0xFFD5E3FC), const Color(0xFF57657A), 'HOẠT ĐỘNG'),
      _UserStatus.locked => (AC.errorContainer, AC.onErrorContainer, 'ĐÃ KHÓA'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AT.cardLabel.copyWith(color: fg, fontSize: 10, letterSpacing: 0.8)),
    );
  }
}

class _RowActions extends StatelessWidget {
  final String uid;
  final _UserStatus status;
  final AdminViewModel vm;
  const _RowActions({required this.uid, required this.status, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _IconAction(
          icon: Icons.visibility_outlined,
          tooltip: 'Xem chi tiết',
          hoverColor: AC.surfaceHighest,
          iconColor: AC.primary,
          onTap: () {},
        ),
        if (status == _UserStatus.locked)
          _IconAction(
            icon: Icons.settings_backup_restore_outlined,
            tooltip: 'Mở khóa người dùng',
            hoverColor: AC.primaryFixed,
            iconColor: AC.primary,
            onTap: () => vm.unbanUser(uid),
          )
        else
          _IconAction(
            icon: Icons.block_outlined,
            tooltip: 'Khóa người dùng',
            hoverColor: AC.errorContainer.withValues(alpha: 0.5),
            iconColor: const Color(0xFFBA1A1A),
            onTap: () => vm.banUser(uid),
          ),
      ],
    );
  }
}

class _IconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color hoverColor;
  final Color iconColor;
  final VoidCallback? onTap;
  const _IconAction(
      {required this.icon,
      required this.tooltip,
      required this.hoverColor,
      required this.iconColor,
      this.onTap});

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _hovered ? widget.hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 18, color: widget.iconColor),
          ),
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  final int count;
  const _PaginationFooter({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AC.surfaceLow,
        border: Border(top: BorderSide(color: Color(0xFFECEEF0))),
      ),
      child: Row(
        children: [
          Text('Hiển thị $count người dùng',
              style: AT.bodyMD.copyWith(fontWeight: FontWeight.w500)),
          const Spacer(),
          _PageBtn(icon: Icons.chevron_left, onTap: () {}),
          const SizedBox(width: 4),
          _PageNum(label: '1', active: true),
          const SizedBox(width: 4),
          _PageBtn(icon: Icons.chevron_right, onTap: () {}),
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
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? AC.surfaceHighest : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, size: 20, color: AC.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _PageNum extends StatefulWidget {
  final String label;
  final bool active;
  const _PageNum({required this.label, this.active = false});

  @override
  State<_PageNum> createState() => _PageNumState();
}

class _PageNumState extends State<_PageNum> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.active
                ? AC.primary
                : _hovered
                    ? AC.surfaceHighest
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AT.nav.copyWith(
                fontSize: 13,
                color: widget.active ? Colors.white : AC.onSurfaceVariant,
                fontWeight:
                    widget.active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Security Banner
// ─────────────────────────────────────────────────────────────────────────────
class _SecurityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AC.surfaceLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cần kiểm tra truy cập hệ thống?',
                    style: AT.sectionTitle.copyWith(fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  'Xem lại nhật ký hoạt động hoặc tạo báo cáo bảo mật đầy đủ cho tất cả các vai trò người dùng.',
                  style: AT.bodyMD,
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AC.onSurface,
              foregroundColor: AC.surface,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Tạo kiểm tra bảo mật',
                style: AT.nav.copyWith(color: AC.surface)),
          ),
        ],
      ),
    );
  }
}
