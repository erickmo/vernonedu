import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Sidebar menu item data.
class SidebarItem {
  final IconData icon;
  final String label;
  final String? badge;
  final List<SidebarItem> children;

  const SidebarItem({
    required this.icon,
    required this.label,
    this.badge,
    this.children = const [],
  });
}

/// DashForge-style sidebar — dark left navigation panel.
class SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const SidebarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const _sidebarWidth = 250.0;

  static const List<SidebarItem> _menuItems = [
    SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    SidebarItem(icon: Icons.menu_book_rounded, label: 'Learning'),
    SidebarItem(icon: Icons.lightbulb_rounded, label: 'Business Ideation'),
    SidebarItem(icon: Icons.rocket_launch_rounded, label: 'Launchpad'),
    SidebarItem(icon: Icons.settings_rounded, label: 'Operations'),
    SidebarItem(icon: Icons.description_rounded, label: 'Administration'),
    SidebarItem(icon: Icons.campaign_rounded, label: 'Marketing'),
    SidebarItem(icon: Icons.people_rounded, label: 'HR Management'),
    SidebarItem(icon: Icons.account_balance_wallet_rounded, label: 'Finance'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _sidebarWidth,
      color: const Color(0xFF1C1C2B),
      child: Column(
        children: [
          _buildLogo(),
          const Divider(color: Color(0xFF2D2D44), height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingM,
              ),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return _buildMenuItem(index, _menuItems[index]);
              },
            ),
          ),
          const Divider(color: Color(0xFF2D2D44), height: 1),
          _buildUserSection(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            'vernon',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'edu',
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, SidebarItem item) {
    final isSelected = selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : null,
            border: isSelected
                ? const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isSelected ? AppColors.primary : const Color(0xFF7987A1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : const Color(0xFF7987A1),
                  ),
                ),
              ),
              if (item.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.badge!,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.3),
            child: Text(
              'S',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siswa',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Entrepreneurship',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF7987A1),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.logout_rounded, color: Color(0xFF7987A1), size: 18),
        ],
      ),
    );
  }
}
