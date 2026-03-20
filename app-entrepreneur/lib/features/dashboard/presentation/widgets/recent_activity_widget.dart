import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Activity item data model.
class ActivityItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  const ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

/// DashForge-style recent activity card — list of recent activities.
class RecentActivityWidget extends StatelessWidget {
  const RecentActivityWidget({super.key});

  static const List<ActivityItem> _activities = [
    ActivityItem(
      icon: Icons.lightbulb_rounded,
      iconColor: Color(0xFFFF6F00),
      title: 'Business Idea Submitted',
      subtitle: 'Coffee shop concept submitted for review',
      time: '2 min ago',
    ),
    ActivityItem(
      icon: Icons.check_circle_rounded,
      iconColor: Color(0xFF10B759),
      title: 'Module Completed',
      subtitle: 'Business Model Canvas - Chapter 3',
      time: '15 min ago',
    ),
    ActivityItem(
      icon: Icons.attach_money_rounded,
      iconColor: Color(0xFF0168FA),
      title: 'Finance Report Updated',
      subtitle: 'Monthly revenue report for March',
      time: '1 hour ago',
    ),
    ActivityItem(
      icon: Icons.people_rounded,
      iconColor: Color(0xFF4D2975),
      title: 'Team Member Added',
      subtitle: 'Ahmad joined Marketing team',
      time: '3 hours ago',
    ),
    ActivityItem(
      icon: Icons.campaign_rounded,
      iconColor: Color(0xFFDC3545),
      title: 'Marketing Campaign Live',
      subtitle: 'Social media campaign launched',
      time: '5 hours ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.divider),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) =>
                _buildActivityItem(_activities[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              // TODO: view all
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View All',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            item.time,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
