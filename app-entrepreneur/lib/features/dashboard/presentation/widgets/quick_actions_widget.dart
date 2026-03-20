import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Quick action item.
class QuickAction {
  final IconData icon;
  final String label;
  final Color color;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });
}

/// DashForge-style quick actions grid.
class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  static const List<QuickAction> _actions = [
    QuickAction(
      icon: Icons.lightbulb_rounded,
      label: 'New Idea',
      color: Color(0xFFFF6F00),
    ),
    QuickAction(
      icon: Icons.add_chart_rounded,
      label: 'Add Report',
      color: Color(0xFF0168FA),
    ),
    QuickAction(
      icon: Icons.person_add_rounded,
      label: 'Add Member',
      color: Color(0xFF10B759),
    ),
    QuickAction(
      icon: Icons.receipt_long_rounded,
      label: 'New Invoice',
      color: Color(0xFF4D2975),
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
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: _actions
                  .map((action) => Expanded(child: _buildActionItem(action)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(QuickAction action) {
    return InkWell(
      onTap: () {
        // TODO: handle action
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              action.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
