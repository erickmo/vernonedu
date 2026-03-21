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

// ── Notification Button ───────────────────────────────────────────────────────

class _NotificationButton extends StatefulWidget {
  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.lavender : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 20,
              color: _hovered ? AppColors.primary : AppColors.textSecondary,
            ),
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
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
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
