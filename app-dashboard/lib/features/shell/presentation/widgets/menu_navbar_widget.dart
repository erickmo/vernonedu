import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class _MenuItem {
  final String label;
  final IconData icon;
  final String route;
  final List<String> activePrefixes;

  const _MenuItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.activePrefixes,
  });
}

const _menuItems = <_MenuItem>[
  _MenuItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/dashboard',
    activePrefixes: ['/dashboard'],
  ),
  _MenuItem(
    label: 'Education',
    icon: Icons.school_outlined,
    route: '/curriculum',
    activePrefixes: [
      '/curriculum',
      '/course-batches',
      '/enrollments',
      '/evaluations',
      '/certificates',
      '/courses',
      '/departments',
    ],
  ),
  _MenuItem(
    label: 'Student',
    icon: Icons.people_outline,
    route: '/students',
    activePrefixes: ['/students', '/talentpool'],
  ),
  _MenuItem(
    label: 'Operations',
    icon: Icons.business_outlined,
    route: '/leads',
    activePrefixes: ['/leads', '/locations', '/partners'],
  ),
  _MenuItem(
    label: 'HR',
    icon: Icons.badge_outlined,
    route: '/hrm',
    activePrefixes: ['/hrm'],
  ),
  _MenuItem(
    label: 'Finance',
    icon: Icons.account_balance_outlined,
    route: '/accounting',
    activePrefixes: ['/accounting', '/payments'],
  ),
  _MenuItem(
    label: 'CRM',
    icon: Icons.support_agent_outlined,
    route: '/crm',
    activePrefixes: ['/crm'],
  ),
  _MenuItem(
    label: 'Business Dev',
    icon: Icons.trending_up_outlined,
    route: '/business-development',
    activePrefixes: ['/business-development', '/projects'],
  ),
  _MenuItem(
    label: 'Approvals',
    icon: Icons.approval_outlined,
    route: '/approvals',
    activePrefixes: ['/approvals', '/notifications', '/settings'],
  ),
];

/// Navbar 2 — Menu bar: daftar menu navigasi utama aplikasi
class MenuNavbarWidget extends StatelessWidget {
  const MenuNavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: _menuItems
                    .map((item) => _MenuItemWidget(
                          item: item,
                          isActive: _isActive(item, currentRoute),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isActive(_MenuItem item, String currentRoute) {
    return item.activePrefixes
        .any((prefix) => currentRoute.startsWith(prefix));
  }
}

class _MenuItemWidget extends StatefulWidget {
  final _MenuItem item;
  final bool isActive;

  const _MenuItemWidget({
    required this.item,
    required this.isActive,
  });

  @override
  State<_MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.item.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 4, vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primarySurface
                  : _hovered
                      ? AppColors.lavender
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.item.icon,
                  size: 15,
                  color: (active || _hovered)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: (active || _hovered)
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    letterSpacing: 0.1,
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
