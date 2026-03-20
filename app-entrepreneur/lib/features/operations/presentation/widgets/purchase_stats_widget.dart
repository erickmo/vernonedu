import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Statistik pembelian — total PO, total value, pending, completed.
class PurchaseStatsWidget extends StatelessWidget {
  const PurchaseStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    final isTablet =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointMobile;
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM,
      crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 2.2 : (isTablet ? 2.0 : 3.0),
      children: const [
        _StatCard(
          icon: Icons.shopping_cart_rounded,
          iconColor: Color(0xFF4D2975),
          label: 'Total PO',
          value: '24',
          sub: 'Purchase Orders',
        ),
        _StatCard(
          icon: Icons.attach_money_rounded,
          iconColor: Color(0xFF0168FA),
          label: 'Total Value',
          value: 'Rp 15.2M',
          sub: 'Bulan ini',
        ),
        _StatCard(
          icon: Icons.pending_actions_rounded,
          iconColor: Color(0xFFFF6F00),
          label: 'Pending',
          value: '7',
          sub: 'Menunggu proses',
        ),
        _StatCard(
          icon: Icons.check_circle_rounded,
          iconColor: Color(0xFF10B759),
          label: 'Completed',
          value: '17',
          sub: 'Selesai',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  sub,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
