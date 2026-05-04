import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Navbar 1 — Brand bar: logo + breadcrumb (kiri), notifikasi + user profile (kanan)
class BrandNavbarWidget extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onLogout;

  const BrandNavbarWidget({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.lavenderMid.withValues(alpha: 0.4)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: Row(
        children: [
          // Brand logo
          _BrandLogo(onTap: () => context.go('/dashboard')),
          const SizedBox(width: AppDimensions.lg),
          // Divider
          Container(width: 1, height: 24, color: AppColors.border),
          const SizedBox(width: AppDimensions.md),
          // Breadcrumb
          Expanded(child: _Breadcrumb()),
          // Notification
          _NotificationButton(),
          const SizedBox(width: AppDimensions.xs),
          // User Profile
          _UserProfileMenu(user: user, onLogout: onLogout),
        ],
      ),
    );
  }
}

// ── Brand Logo ────────────────────────────────────────────────────────────────

class _BrandLogo extends StatefulWidget {
  final VoidCallback onTap;
  const _BrandLogo({required this.onTap});

  @override
  State<_BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<_BrandLogo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: _hovered ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // V icon
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6B4FE0), Color(0xFF00BFA5)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Brand text
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'VERNON',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const TextSpan(
                      text: 'EDU',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B4FE0),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Breadcrumb ────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  static const _routeLabels = <String, String>{
    'dashboard': 'Dashboard',
    'curriculum': 'Education',
    'course-batches': 'Batch',
    'enrollments': 'Enrollment',
    'evaluations': 'Evaluasi',
    'students': 'Student',
    'certificates': 'Sertifikat',
    'payments': 'Pembayaran',
    'talentpool': 'TalentPool',
    'business-development': 'Pengembangan',
    'departments': 'Departemen',
    'crm': 'Business Development',
    'hrm': 'HR',
    'accounting': 'Finance',
    'projects': 'Project',
  };

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    final segments = uri
        .split('/')
        .where((s) => s.isNotEmpty && !_isUuid(s) && !_isId(s))
        .toList();

    if (segments.isEmpty) return const SizedBox.shrink();

    final crumbs = segments
        .map((s) => _routeLabels[s] ?? _capitalize(s))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < crumbs.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: AppColors.textHint,
                ),
              ),
            Text(
              crumbs[i],
              style: TextStyle(
                fontSize: 13,
                color: i == crumbs.length - 1
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: i == crumbs.length - 1
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isUuid(String s) =>
      RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
          .hasMatch(s);

  bool _isId(String s) => RegExp(r'^[a-f0-9]{24,}$').hasMatch(s);

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Notification Button with Dropdown ──────────────────────────────────────────

class _NotificationItem {
  final String title;
  final String body;
  final String time;
  final bool unread;

  const _NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
  });
}

const _mockNotifications = <_NotificationItem>[
  _NotificationItem(
    title: 'Batch Baru',
    body: 'Batch "Web Development Angkatan 5" telah dibuat.',
    time: '5 menit lalu',
    unread: true,
  ),
  _NotificationItem(
    title: 'Enrollment Baru',
    body: 'Ahmad Fauzi mendaftar ke batch "Flutter Mobile Dev".',
    time: '1 jam lalu',
    unread: true,
  ),
  _NotificationItem(
    title: 'Approval Dibutuhkan',
    body: 'Pengajuan kursus "AI Fundamentals" menunggu persetujuan.',
    time: '3 jam lalu',
    unread: true,
  ),
  _NotificationItem(
    title: 'Pembayaran Diterima',
    body: 'Invoice #INV-2026-041 telah dibayar lunas.',
    time: '1 hari lalu',
    unread: false,
  ),
  _NotificationItem(
    title: 'Sertifikat Terbit',
    body: 'Sertifikat competency untuk Budi Santoso telah diterbitkan.',
    time: '2 hari lalu',
    unread: false,
  ),
];

class _NotificationButton extends StatefulWidget {
  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  bool _hovered = false;
  bool _dropdownOpen = false;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  int get _unreadCount =>
      _mockNotifications.where((n) => n.unread).length;

  void _toggleDropdown() {
    if (_dropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox;
    final size = box.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Invisible tap-away layer
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          // Dropdown positioned below button
          CompositedTransformFollower(
            link: _layerLink,
            offset: Offset(0, size.height + 4),
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            child: Material(
              elevation: 12,
              shadowColor: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: _NotificationDropdown(
                notifications: _mockNotifications,
                onViewAll: () {
                  _closeDropdown();
                  GoRouter.of(context).go('/notifications');
                },
                onMarkAllRead: _closeDropdown,
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _dropdownOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _dropdownOpen = false);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hovered || _dropdownOpen
                  ? AppColors.lavender
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: _hovered || _dropdownOpen
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                if (_unreadCount > 0)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6B4FE0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_unreadCount > 9 ? '9+' : _unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

class _NotificationDropdown extends StatelessWidget {
  final List<_NotificationItem> notifications;
  final VoidCallback onViewAll;
  final VoidCallback onMarkAllRead;

  const _NotificationDropdown({
    required this.notifications,
    required this.onViewAll,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 440),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm + 2,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Text(
                  'Notifikasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onMarkAllRead,
                  child: Text(
                    'Tandai semua dibaca',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B4FE0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notification list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(item: n);
              },
            ),
          ),
          // Footer
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onViewAll,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.radiusLg),
                  bottomRight: Radius.circular(AppDimensions.radiusLg),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  child: const Text(
                    'Lihat semua notifikasi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B4FE0),
                    ),
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

class _NotificationTile extends StatefulWidget {
  final _NotificationItem item;
  const _NotificationTile({required this.item});

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: item.unread
            ? AppColors.lavender.withValues(alpha: _hovered ? 0.8 : 0.5)
            : _hovered
                ? AppColors.surfaceVariant
                : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: item.unread ? const Color(0xFF6B4FE0) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: item.unread ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
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

// ── User Profile Dropdown ─────────────────────────────────────────────────────

class _UserProfileMenu extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onLogout;

  const _UserProfileMenu({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 8,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4FE0), AppColors.primary],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  user.rolesLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppDimensions.xs),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.person_outline,
                    size: 16, color: Color(0xFF6B4FE0)),
              ),
              const SizedBox(width: 10),
              const Text('Profil Saya',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'password',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.lock_outline,
                    size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Text('Ganti Password',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: const Icon(Icons.logout,
                    size: 16, color: AppColors.error),
              ),
              const SizedBox(width: 10),
              const Text('Keluar',
                  style: TextStyle(fontSize: 13, color: AppColors.error)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
    );
  }
}
