import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/domain/entities/user_entity.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  final bool Function(UserRole) hasAccess;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.hasAccess,
  });
}

final _navItems = <_NavItem>[
  // ── Dashboard ────────────────────────────────────────────────────────────
  _NavItem(
    label: AppStrings.navDashboard,
    icon: Icons.dashboard_outlined,
    route: '/dashboard',
    hasAccess: (_) => true,
  ),

  // ── Education ────────────────────────────────────────────────────────────
  _NavItem(
    label: 'Course',
    icon: Icons.menu_book_outlined,
    route: '/curriculum',
    hasAccess: (r) => r.canManageCourse || r == UserRole.facilitator,
  ),
  _NavItem(
    label: AppStrings.navCourseBatch,
    icon: Icons.class_outlined,
    route: '/course-batches',
    hasAccess: (r) =>
        r.canManageCourse ||
        r == UserRole.facilitator ||
        r.isOperationTeam,
  ),
  _NavItem(
    label: AppStrings.navEnrollment,
    icon: Icons.how_to_reg_outlined,
    route: '/enrollments',
    hasAccess: (r) => r.canManageStudent || r.canManageCourse,
  ),
  _NavItem(
    label: AppStrings.navStudent,
    icon: Icons.people_outline,
    route: '/students',
    hasAccess: (r) => r.canManageStudent,
  ),
  _NavItem(
    label: 'TalentPool',
    icon: Icons.workspace_premium_outlined,
    route: '/talentpool',
    hasAccess: (r) => r.canViewTalentPool,
  ),
  _NavItem(
    label: AppStrings.navCertificate,
    icon: Icons.card_membership_outlined,
    route: '/certificates',
    hasAccess: (r) => r.canManageCourse || r == UserRole.customerService,
  ),
  _NavItem(
    label: AppStrings.navDepartment,
    icon: Icons.corporate_fare_outlined,
    route: '/departments',
    hasAccess: (r) =>
        r == UserRole.director ||
        r == UserRole.educationLeader ||
        r == UserRole.deptLeader,
  ),

  // ── Operations ───────────────────────────────────────────────────────────
  _NavItem(
    label: AppStrings.navLeads,
    icon: Icons.contacts_outlined,
    route: '/leads',
    hasAccess: (r) =>
        r == UserRole.director ||
        r == UserRole.operationLeader ||
        r == UserRole.customerService ||
        r == UserRole.marketing,
  ),
  _NavItem(
    label: AppStrings.navLocations,
    icon: Icons.location_on_outlined,
    route: '/locations',
    hasAccess: (r) => r.canManageLocation,
  ),
  _NavItem(
    label: AppStrings.navPayment,
    icon: Icons.receipt_long_outlined,
    route: '/payments',
    hasAccess: (r) => r.canManageStudent || r.canViewAccounting,
  ),

  // ── CRM & Partners ───────────────────────────────────────────────────────
  _NavItem(
    label: AppStrings.navCrm,
    icon: Icons.support_agent_outlined,
    route: '/crm',
    hasAccess: (r) => r.canViewCrm,
  ),
  _NavItem(
    label: AppStrings.navPartners,
    icon: Icons.handshake_outlined,
    route: '/partners',
    hasAccess: (r) =>
        r == UserRole.director ||
        r == UserRole.operationLeader ||
        r == UserRole.educationLeader,
  ),

  // ── Finance & HR ─────────────────────────────────────────────────────────
  _NavItem(
    label: AppStrings.navAccounting,
    icon: Icons.account_balance_outlined,
    route: '/accounting',
    hasAccess: (r) => r.canViewAccounting,
  ),
  _NavItem(
    label: AppStrings.navHrm,
    icon: Icons.badge_outlined,
    route: '/hrm',
    hasAccess: (r) => r.canViewHrm,
  ),

  // ── Director-level ───────────────────────────────────────────────────────
  _NavItem(
    label: AppStrings.navProject,
    icon: Icons.task_alt_outlined,
    route: '/projects',
    hasAccess: (r) =>
        r == UserRole.director ||
        r == UserRole.educationLeader ||
        r == UserRole.operationLeader,
  ),
  _NavItem(
    label: AppStrings.navBusinessDev,
    icon: Icons.trending_up_outlined,
    route: '/business-development',
    hasAccess: (r) => r.canViewBusinessDev,
  ),

  // ── Global ───────────────────────────────────────────────────────────────
  _NavItem(
    label: AppStrings.navApprovals,
    icon: Icons.approval_outlined,
    route: '/approvals',
    hasAccess: (r) => r.hasApprovals,
  ),
  _NavItem(
    label: AppStrings.navNotifications,
    icon: Icons.notifications_outlined,
    route: '/notifications',
    hasAccess: (r) => r.canAccessAdmin,
  ),
  _NavItem(
    label: AppStrings.navSettings,
    icon: Icons.settings_outlined,
    route: '/settings',
    hasAccess: (r) => r == UserRole.director,
  ),
];

class SidebarWidget extends StatelessWidget {
  final UserEntity user;
  final bool collapsed;
  final VoidCallback onToggle;

  const SidebarWidget({
    super.key,
    required this.user,
    required this.collapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final width =
        collapsed ? AppDimensions.sidebarCollapsed : AppDimensions.sidebarWidth;
    final currentRoute = GoRouterState.of(context).uri.toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
      ),
      child: Column(
        children: [
          // Header
          _SidebarHeader(collapsed: collapsed, onToggle: onToggle),
          const Divider(color: AppColors.sidebarDivider, height: 1),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
              children: _navItems
                  .where((item) => item.hasAccess(user.role))
                  .map((item) => _NavTile(
                        item: item,
                        collapsed: collapsed,
                        isActive: currentRoute.startsWith(item.route),
                      ))
                  .toList(),
            ),
          ),
          // User info
          const Divider(color: AppColors.sidebarDivider, height: 1),
          _SidebarUserInfo(user: user, collapsed: collapsed),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggle;

  const _SidebarHeader({required this.collapsed, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.topbarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        child: Row(
          children: [
            const Icon(Icons.school_rounded, color: Colors.white, size: 28),
            if (!collapsed) ...[
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  'VernonEdu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const Spacer(),
            IconButton(
              icon: Icon(
                collapsed ? Icons.menu_open : Icons.menu,
                color: AppColors.sidebarTextMuted,
                size: AppDimensions.iconMd,
              ),
              onPressed: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool collapsed;
  final bool isActive;

  const _NavTile({
    required this.item,
    required this.collapsed,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 2,
      ),
      child: Tooltip(
        message: collapsed ? item.label : '',
        preferBelow: false,
        child: Material(
          color: isActive ? AppColors.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            hoverColor: AppColors.sidebarHover,
            onTap: () => context.go(item.route),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal:
                    collapsed ? AppDimensions.sm : AppDimensions.md,
                vertical: AppDimensions.sm + 2,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    color: isActive
                        ? Colors.white
                        : AppColors.sidebarTextMuted,
                    size: AppDimensions.iconMd,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : AppColors.sidebarText,
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarUserInfo extends StatelessWidget {
  final UserEntity user;
  final bool collapsed;

  const _SidebarUserInfo({required this.user, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppDimensions.avatarSm,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: AppColors.sidebarText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.role.label,
                    style: const TextStyle(
                      color: AppColors.sidebarTextMuted,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
