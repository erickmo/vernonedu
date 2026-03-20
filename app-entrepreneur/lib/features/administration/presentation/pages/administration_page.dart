import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/admin_card_widget.dart';
import '../widgets/admin_section_header.dart';

/// Administration page — system configuration, users, permissions, audit logs, reports.
class AdministrationPage extends StatelessWidget {
  const AdministrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: AppDimensions.spacingL),
          const AdminSectionHeader(title: 'System Management'),
          const SizedBox(height: AppDimensions.spacingM),
          _buildSystemManagementCards(context),
          const SizedBox(height: AppDimensions.spacingL),
          const AdminSectionHeader(title: 'User Management'),
          const SizedBox(height: AppDimensions.spacingM),
          _buildUserManagementCards(context),
          const SizedBox(height: AppDimensions.spacingL),
          const AdminSectionHeader(title: 'Reports & Monitoring'),
          const SizedBox(height: AppDimensions.spacingM),
          _buildReportsCards(context),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Administration',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          'System configuration, user management, and monitoring.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemManagementCards(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;

    final gridCrossAxisCount = isDesktop ? 3 : 1;

    return GridView.count(
      crossAxisCount: gridCrossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM,
      crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 1.2 : 1.5,
      children: const [
        AdminCardWidget(
          icon: Icons.settings_rounded,
          iconColor: Color(0xFF4D2975),
          iconBgColor: Color(0x1A4D2975),
          title: 'Settings',
          description: 'Configure system preferences',
        ),
        AdminCardWidget(
          icon: Icons.security_rounded,
          iconColor: Color(0xFF0168FA),
          iconBgColor: Color(0x1A0168FA),
          title: 'Security',
          description: 'Manage security & backups',
        ),
        AdminCardWidget(
          icon: Icons.storage_rounded,
          iconColor: Color(0xFFFF6F00),
          iconBgColor: Color(0x1AFF6F00),
          title: 'Database',
          description: 'Database & storage management',
        ),
      ],
    );
  }

  Widget _buildUserManagementCards(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;

    final gridCrossAxisCount = isDesktop ? 3 : 1;

    return GridView.count(
      crossAxisCount: gridCrossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM,
      crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 1.2 : 1.5,
      children: const [
        AdminCardWidget(
          icon: Icons.people_rounded,
          iconColor: Color(0xFF10B759),
          iconBgColor: Color(0x1A10B759),
          title: 'Users',
          description: 'Manage user accounts',
        ),
        AdminCardWidget(
          icon: Icons.admin_panel_settings_rounded,
          iconColor: Color(0xFF9C27B0),
          iconBgColor: Color(0x1A9C27B0),
          title: 'Roles & Permissions',
          description: 'Configure access control',
        ),
        AdminCardWidget(
          icon: Icons.assignment_rounded,
          iconColor: Color(0xFF00BCD4),
          iconBgColor: Color(0x1A00BCD4),
          title: 'Approvals',
          description: 'Manage approval workflows',
        ),
      ],
    );
  }

  Widget _buildReportsCards(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;

    final gridCrossAxisCount = isDesktop ? 3 : 1;

    return GridView.count(
      crossAxisCount: gridCrossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM,
      crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 1.2 : 1.5,
      children: const [
        AdminCardWidget(
          icon: Icons.analytics_rounded,
          iconColor: Color(0xFFE91E63),
          iconBgColor: Color(0x1AE91E63),
          title: 'Analytics',
          description: 'System analytics & insights',
        ),
        AdminCardWidget(
          icon: Icons.history_rounded,
          iconColor: Color(0xFF673AB7),
          iconBgColor: Color(0x1A673AB7),
          title: 'Audit Logs',
          description: 'User activity & system logs',
        ),
        AdminCardWidget(
          icon: Icons.assessment_rounded,
          iconColor: Color(0xFFF57C00),
          iconBgColor: Color(0x1AF57C00),
          title: 'Reports',
          description: 'Generate system reports',
        ),
      ],
    );
  }
}
