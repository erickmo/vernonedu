import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// DashForge-style top navigation bar — search, notifications, user avatar.
class TopNavbarWidget extends StatelessWidget {
  final VoidCallback? onMenuPressed;

  const TopNavbarWidget({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < AppDimensions.breakpointTablet;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: onMenuPressed,
            ),
          if (!isMobile) _buildSearchBar(),
          const Spacer(),
          _buildNotificationIcon(),
          const SizedBox(width: AppDimensions.spacingS),
          _buildMessageIcon(),
          const SizedBox(width: AppDimensions.spacingM),
          _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      width: 280,
      height: 38,
      child: TextField(
        style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textHint,
          ),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Badge(
      label: Text(
        '3',
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppColors.error,
      child: IconButton(
        icon: const Icon(
          Icons.notifications_outlined,
          color: AppColors.textSecondary,
          size: 22,
        ),
        onPressed: () {
          // TODO: open notifications
        },
      ),
    );
  }

  Widget _buildMessageIcon() {
    return Badge(
      label: Text(
        '5',
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600),
      ),
      backgroundColor: AppColors.primary,
      child: IconButton(
        icon: const Icon(
          Icons.mail_outlined,
          color: AppColors.textSecondary,
          size: 22,
        ),
        onPressed: () {
          // TODO: open messages
        },
      ),
    );
  }

  Widget _buildUserAvatar() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      onSelected: (value) {
        // TODO: handle menu selection
      },
      itemBuilder: (context) => [
        _buildPopupItem(Icons.person_outline, 'My Profile'),
        _buildPopupItem(Icons.settings_outlined, 'Settings'),
        const PopupMenuDivider(),
        _buildPopupItem(Icons.logout_rounded, 'Sign Out'),
      ],
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Text(
              'S',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(IconData icon, String label) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
