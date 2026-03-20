import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import '../router/app_router.dart';
import '../utils/responsive.dart';
import 'gradient_button.dart';

/// Navbar VernonEdu — Glass morphism saat scroll, transparan di top.
class NavbarWidget extends StatefulWidget {
  const NavbarWidget({super.key});

  @override
  State<NavbarWidget> createState() => _NavbarWidgetState();
}

class _NavbarWidgetState extends State<NavbarWidget> {
  bool _isScrolled = false;
  bool _isMobileMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final currentPath = GoRouterState.of(context).uri.path;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isScrolled
          ? AppDimensions.navbarHeightScrolled
          : AppDimensions.navbarHeight,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _isScrolled ? 20 : 0,
            sigmaY: _isScrolled ? 20 : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _isScrolled
                  ? AppColors.bgPrimary.withValues(alpha: 0.85)
                  : Colors.transparent,
              border: _isScrolled
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
              child: isMobile
                  ? _MobileNav(
                      isMenuOpen: _isMobileMenuOpen,
                      currentPath: currentPath,
                      onMenuToggle: () => setState(
                        () => _isMobileMenuOpen = !_isMobileMenuOpen,
                      ),
                    )
                  : _DesktopNav(currentPath: currentPath),
            ),
          ),
        ),
      ),
    );
  }
}

/// Desktop navigation layout.
class _DesktopNav extends StatelessWidget {
  final String currentPath;

  const _DesktopNav({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LogoWidget(),
        const Spacer(),
        _NavItem(label: 'Beranda', path: AppRouter.home, current: currentPath),
        const SizedBox(width: AppDimensions.s32),
        _NavItem(label: 'Kursus', path: AppRouter.kursus, current: currentPath),
        const SizedBox(width: AppDimensions.s32),
        _NavItem(label: 'Update', path: AppRouter.update, current: currentPath),
        const SizedBox(width: AppDimensions.s32),
        _NavItem(
          label: 'Hubungi Kami',
          path: AppRouter.hubungi,
          current: currentPath,
        ),
        const SizedBox(width: AppDimensions.s48),
        GradientButton(
          label: 'Mulai Belajar',
          onTap: () => context.go(AppRouter.kursus),
          height: 44,
          horizontalPadding: 24,
        ),
      ],
    );
  }
}

/// Mobile navigation layout with hamburger.
class _MobileNav extends StatelessWidget {
  final bool isMenuOpen;
  final String currentPath;
  final VoidCallback onMenuToggle;

  const _MobileNav({
    required this.isMenuOpen,
    required this.currentPath,
    required this.onMenuToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LogoWidget(),
        const Spacer(),
        GestureDetector(
          onTap: onMenuToggle,
          child: AnimatedRotation(
            turns: isMenuOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
              color: AppColors.textPrimary,
              size: AppDimensions.iconL,
            ),
          ),
        ),
      ],
    );
  }
}

/// Logo widget.
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

/// Single nav item with active indicator.
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
                    : LinearGradient(
                        colors: [
                          AppColors.textSecondary.withValues(alpha: 0.5),
                          AppColors.textSecondary.withValues(alpha: 0.5),
                        ],
                      ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scaffold dengan navbar bawaan — dipakai di semua halaman.
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
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Spacer untuk navbar
                SizedBox(height: AppDimensions.navbarHeight),
                widget.body,
              ],
            ),
          ),
          // Navbar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ScrolledNavbar(isScrolled: _isScrolled),
          ),
        ],
      ),
    );
  }
}

class _ScrolledNavbar extends StatelessWidget {
  final bool isScrolled;

  const _ScrolledNavbar({required this.isScrolled});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final currentPath = GoRouterState.of(context).uri.path;

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
              child: isMobile
                  ? Row(
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
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          onSelected: (path) => context.go(path),
                          itemBuilder: (_) => [
                            _menuItem('Beranda', AppRouter.home),
                            _menuItem('Kursus', AppRouter.kursus),
                            _menuItem('Update', AppRouter.update),
                            _menuItem('Hubungi Kami', AppRouter.hubungi),
                          ],
                        ),
                      ],
                    )
                  : _DesktopNav(currentPath: currentPath),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String label, String path) {
    return PopupMenuItem(
      value: path,
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
