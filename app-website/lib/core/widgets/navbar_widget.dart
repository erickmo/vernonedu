import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import '../router/app_router.dart';
import '../utils/responsive.dart';
import 'gradient_button.dart';

// ─── Dropdown item data ────────────────────────────────────────────────────────

typedef _MenuItem = ({String label, String path, IconData? icon});

const _programItems = <_MenuItem>[
  (label: 'Program Karir', path: AppRouter.programKarir, icon: Icons.rocket_launch_outlined),
  (label: 'Kursus Reguler', path: AppRouter.programReguler, icon: Icons.school_outlined),
  (label: 'Kursus Privat', path: AppRouter.programPrivat, icon: Icons.person_outline),
  (label: 'Sertifikasi', path: AppRouter.programSertifikasi, icon: Icons.verified_outlined),
];

const _untukItems = <_MenuItem>[
  (label: 'Untuk Universitas', path: AppRouter.untukUniversitas, icon: Icons.account_balance_outlined),
  (label: 'Untuk Sekolah', path: AppRouter.untukSekolah, icon: Icons.school_outlined),
  (label: 'Untuk Korporat', path: AppRouter.untukKorporat, icon: Icons.business_outlined),
  (label: 'Untuk Individu', path: AppRouter.untukIndividu, icon: Icons.person_outlined),
];

// ─── NavbarWidget ─────────────────────────────────────────────────────────────

/// Navbar VernonEdu — Glass morphism saat scroll, transparan di top.
class NavbarWidget extends StatefulWidget {
  const NavbarWidget({super.key});

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final currentPath = GoRouterState.of(context).uri.path;

    return _NavbarShell(
      isScrolled: false,
      child: isMobile
          ? _MobileNavContent(currentPath: currentPath)
          : _DesktopNavContent(currentPath: currentPath),
    );
  }
}

// ─── WebScaffold ───────────────────────────────────────────────────────────────

/// Scaffold con navbar fissa — usato in tutte le pagine.
class WebScaffold extends StatefulWidget {
  final Widget body;
  final bool showFooter;

  const WebScaffold({
    super.key,
    required this.body,
    this.showFooter = true,
  });

  @override
  State<WebScaffold> createState() => _WebScaffoldState();
}

class _WebScaffoldState extends State<WebScaffold> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final scrolled = _scrollController.offset > 40;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final currentPath = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                SizedBox(height: AppDimensions.navbarHeight),
                widget.body,
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _NavbarShell(
              isScrolled: _isScrolled,
              child: isMobile
                  ? _MobileNavContent(currentPath: currentPath)
                  : _DesktopNavContent(currentPath: currentPath),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared shell ─────────────────────────────────────────────────────────────

class _NavbarShell extends StatelessWidget {
  final bool isScrolled;
  final Widget child;

  const _NavbarShell({required this.isScrolled, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isScrolled
          ? AppDimensions.navbarHeightScrolled
          : AppDimensions.navbarHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isScrolled ? 20 : 0,
            sigmaY: isScrolled ? 20 : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isScrolled
                  ? AppColors.bgPrimary.withValues(alpha: 0.9)
                  : Colors.transparent,
              border: isScrolled
                  ? const Border(
                      bottom: BorderSide(color: AppColors.border, width: 1),
                    )
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? AppDimensions.s24
                    : Responsive.sectionPaddingH(context),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Desktop nav ──────────────────────────────────────────────────────────────

class _DesktopNavContent extends StatelessWidget {
  final String currentPath;

  const _DesktopNavContent({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LogoWidget(),
        const Spacer(),
        _DropdownNavItem(
          label: 'Program',
          items: _programItems,
          currentPath: currentPath,
          isActiveWhen: (p) => p.startsWith('/program'),
        ),
        const SizedBox(width: AppDimensions.s32),
        _DropdownNavItem(
          label: 'Untuk',
          items: _untukItems,
          currentPath: currentPath,
          isActiveWhen: (p) => p.startsWith('/untuk'),
        ),
        const SizedBox(width: AppDimensions.s32),
        _NavItem(
          label: 'Katalog',
          path: AppRouter.katalog,
          current: currentPath,
        ),
        const SizedBox(width: AppDimensions.s32),
        _NavItem(
          label: 'Update',
          path: AppRouter.update,
          current: currentPath,
        ),
        const SizedBox(width: AppDimensions.s32),
        _NavItem(
          label: 'Hubungi',
          path: AppRouter.hubungi,
          current: currentPath,
        ),
        const SizedBox(width: AppDimensions.s48),
        GradientButton(
          label: 'Daftar Sekarang',
          onTap: () => context.go(AppRouter.katalog),
          height: 44,
          horizontalPadding: 24,
        ),
      ],
    );
  }
}

// ─── Mobile nav ───────────────────────────────────────────────────────────────

class _MobileNavContent extends StatelessWidget {
  final String currentPath;

  const _MobileNavContent({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LogoWidget(),
        const Spacer(),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.menu_rounded,
            color: AppColors.textPrimary,
          ),
          color: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.r12),
            side: const BorderSide(color: AppColors.border),
          ),
          onSelected: (path) => context.go(path),
          itemBuilder: (_) => [
            _menuSection('PROGRAM'),
            ..._programItems.map((i) => _menuItem(i.label, i.path)),
            _menuDivider(),
            _menuSection('UNTUK'),
            ..._untukItems.map((i) => _menuItem(i.label, i.path)),
            _menuDivider(),
            _menuItem('Katalog', AppRouter.katalog),
            _menuItem('Update', AppRouter.update),
            _menuItem('Hubungi', AppRouter.hubungi),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String label, String path) =>
      PopupMenuItem(
        value: path,
        child: Text(label,
            style: const TextStyle(color: AppColors.textPrimary)),
      );

  PopupMenuItem<String> _menuSection(String title) => PopupMenuItem(
        enabled: false,
        height: 28,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );

  PopupMenuItem<String> _menuDivider() => const PopupMenuItem(
        enabled: false,
        height: 1,
        padding: EdgeInsets.zero,
        child: Divider(height: 1, color: AppColors.border),
      );
}

// ─── Logo ─────────────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRouter.home),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Vernon',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Edu',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  foreground: Paint()
                    ..shader = AppColors.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 80, 30),
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Simple nav item ──────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  final String label;
  final String path;
  final String current;

  const _NavItem({
    required this.label,
    required this.path,
    required this.current,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  bool get _isActive => widget.current == widget.path;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.path),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: _isActive
                  ? AppTextStyles.navLinkActive
                  : AppTextStyles.navLink.copyWith(
                      color: _hovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: _isActive || _hovered ? 24 : 0,
              decoration: BoxDecoration(
                gradient: _isActive
                    ? AppColors.primaryGradient
                    : LinearGradient(colors: [
                        AppColors.textSecondary.withValues(alpha: 0.5),
                        AppColors.textSecondary.withValues(alpha: 0.5),
                      ]),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dropdown nav item ────────────────────────────────────────────────────────

class _DropdownNavItem extends StatefulWidget {
  final String label;
  final List<_MenuItem> items;
  final String currentPath;
  final bool Function(String path) isActiveWhen;

  const _DropdownNavItem({
    required this.label,
    required this.items,
    required this.currentPath,
    required this.isActiveWhen,
  });

  @override
  State<_DropdownNavItem> createState() => _DropdownNavItemState();
}

class _DropdownNavItemState extends State<_DropdownNavItem> {
  bool _hovered = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  Timer? _hideTimer;

  bool get _isActive => widget.isActiveWhen(widget.currentPath);

  @override
  void dispose() {
    _hideTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _showOverlay() {
    _hideTimer?.cancel();
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (_) => _DropdownOverlay(
        layerLink: _layerLink,
        items: widget.items,
        currentPath: widget.currentPath,
        onHoverEnter: _showOverlay,
        onHoverExit: _scheduleHide,
        navHeight: AppDimensions.navbarHeightScrolled,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _scheduleHide() {
    _hideTimer = Timer(const Duration(milliseconds: 150), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() => _hovered = true);
          _showOverlay();
        },
        onExit: (_) {
          setState(() => _hovered = false);
          _scheduleHide();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: _isActive
                      ? AppTextStyles.navLinkActive
                      : AppTextStyles.navLink.copyWith(
                          color: _hovered
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: _hovered ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _hovered || _isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: _isActive || _hovered ? 24 : 0,
              decoration: BoxDecoration(
                gradient: _isActive
                    ? AppColors.primaryGradient
                    : LinearGradient(colors: [
                        AppColors.textSecondary.withValues(alpha: 0.5),
                        AppColors.textSecondary.withValues(alpha: 0.5),
                      ]),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dropdown overlay panel ───────────────────────────────────────────────────

class _DropdownOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final List<_MenuItem> items;
  final String currentPath;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final double navHeight;

  const _DropdownOverlay({
    required this.layerLink,
    required this.items,
    required this.currentPath,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.navHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 240,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, navHeight - 8),
        child: Material(
          color: Colors.transparent,
          child: MouseRegion(
            onEnter: (_) => onHoverEnter(),
            onExit: (_) => onHoverExit(),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppDimensions.r16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandPurple.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.r16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: items
                      .map(
                        (item) => _DropdownItemTile(
                          item: item,
                          isActive: currentPath.startsWith(item.path),
                          onTap: () => context.go(item.path),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownItemTile extends StatefulWidget {
  final _MenuItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _DropdownItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_DropdownItemTile> createState() => _DropdownItemTileState();
}

class _DropdownItemTileState extends State<_DropdownItemTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.s20,
            vertical: AppDimensions.s16,
          ),
          color: _hovered || widget.isActive
              ? AppColors.bgSurface
              : Colors.transparent,
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: AppDimensions.iconS,
                  color: widget.isActive
                      ? AppColors.brandPurple
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.s12),
              ],
              Text(
                widget.item.label,
                style: AppTextStyles.navLink.copyWith(
                  color: widget.isActive
                      ? AppColors.brandPurple
                      : _hovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                  fontWeight: widget.isActive
                      ? FontWeight.w600
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
