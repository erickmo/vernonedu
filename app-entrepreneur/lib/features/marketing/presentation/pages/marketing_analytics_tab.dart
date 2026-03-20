import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/channel_performance_widget.dart';

/// Tab Analytics — channel performance + ROI + engagement metrics.
class MarketingAnalyticsTab extends StatelessWidget {
  const MarketingAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(child: ChannelPerformanceWidget()),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(child: _buildRoiCard()),
              ],
            )
          else ...[
            const ChannelPerformanceWidget(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildRoiCard(),
          ],
          const SizedBox(height: AppDimensions.spacingL),
          _buildEngagementMetrics(),
        ],
      ),
    );
  }

  Widget _buildRoiCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Marketing ROI', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppDimensions.spacingM),
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd]),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              children: [
                Text('Return on Investment', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 8),
                Text('15.5x', style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Rp 32.5M revenue / Rp 2.1M spend', style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          ..._roiItems.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 6),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(item.label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary))),
              Text(item.value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ]),
          )),
          const SizedBox(height: AppDimensions.spacingS),
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Engagement Metrics', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Wrap(
              spacing: AppDimensions.spacingM,
              runSpacing: AppDimensions.spacingM,
              children: _engagementItems.map((item) {
                return SizedBox(
                  width: 150,
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingM),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: item.color.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(item.icon, color: item.color, size: 24),
                        const SizedBox(height: 8),
                        Text(item.value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: item.color)),
                        const SizedBox(height: 2),
                        Text(item.label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.trending_up_rounded, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(item.change, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static const _roiItems = [
    _RoiItem('Cost per Acquisition (CPA)', 'Rp 46.7K', Color(0xFF4D2975)),
    _RoiItem('Customer Lifetime Value (CLV)', 'Rp 722K', Color(0xFF10B759)),
    _RoiItem('CLV:CPA Ratio', '15.5x', Color(0xFF0168FA)),
    _RoiItem('Payback Period', '< 1 bulan', Color(0xFFFF6F00)),
  ];

  static const _engagementItems = [
    _EngagementItem('Impressions', '8.5K', '+18%', Icons.visibility_rounded, Color(0xFF4D2975)),
    _EngagementItem('Clicks', '420', '+12%', Icons.mouse_rounded, Color(0xFF0168FA)),
    _EngagementItem('Shares', '85', '+25%', Icons.share_rounded, Color(0xFF10B759)),
    _EngagementItem('Comments', '156', '+8%', Icons.chat_bubble_rounded, Color(0xFFFF6F00)),
    _EngagementItem('Saves', '210', '+32%', Icons.bookmark_rounded, Color(0xFFDC3545)),
    _EngagementItem('DMs', '45', '+15%', Icons.mail_rounded, Color(0xFF1DA1F2)),
  ];
}

class _RoiItem {
  final String label;
  final String value;
  final Color color;
  const _RoiItem(this.label, this.value, this.color);
}

class _EngagementItem {
  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  const _EngagementItem(this.label, this.value, this.change, this.icon, this.color);
}
