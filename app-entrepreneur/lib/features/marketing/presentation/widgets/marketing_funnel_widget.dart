import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Marketing funnel — AIDA (Awareness, Interest, Desire, Action) + Flywheel recap.
class MarketingFunnelWidget extends StatelessWidget {
  const MarketingFunnelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

    return Container(
      width: double.infinity,
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
                const Icon(Icons.filter_alt_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Marketing Funnel', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: isDesktop ? _buildDesktopFunnel() : _buildMobileFunnel(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFunnel() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Funnel visual
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildFunnelStage('AWARENESS', 'Menarik perhatian target market', Icons.visibility_rounded, const Color(0xFF4D2975), 1.0, '1,200 reach'),
              _buildFunnelStage('INTEREST', 'Membangun ketertarikan dengan content', Icons.favorite_rounded, const Color(0xFF0168FA), 0.75, '450 engaged'),
              _buildFunnelStage('DESIRE', 'Menciptakan keinginan untuk membeli', Icons.star_rounded, const Color(0xFFFF6F00), 0.55, '120 leads'),
              _buildFunnelStage('ACTION', 'Konversi menjadi customer', Icons.shopping_bag_rounded, const Color(0xFF10B759), 0.35, '45 customers'),
              _buildFunnelStage('RETENTION', 'Menjaga loyalitas customer', Icons.repeat_rounded, const Color(0xFFDC3545), 0.25, '28 repeat'),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingL),
        // Strategy per stage
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Strategi per Tahap', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: AppDimensions.spacingM),
              _strategyCard('Awareness', [
                'Social media ads (Instagram, TikTok)',
                'SEO & blog content',
                'Kolaborasi dengan influencer',
              ], const Color(0xFF4D2975)),
              _strategyCard('Interest', [
                'Educational content & tutorial',
                'Email newsletter',
                'Free sample / trial',
              ], const Color(0xFF0168FA)),
              _strategyCard('Desire', [
                'Testimonial & social proof',
                'Limited time offer',
                'Product demo',
              ], const Color(0xFFFF6F00)),
              _strategyCard('Action', [
                'Clear CTA di semua channel',
                'Easy checkout process',
                'First-time buyer discount',
              ], const Color(0xFF10B759)),
              _strategyCard('Retention', [
                'Loyalty program',
                'Post-purchase follow up',
                'Referral incentive',
              ], const Color(0xFFDC3545)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileFunnel() {
    return Column(
      children: [
        _buildFunnelStage('AWARENESS', 'Menarik perhatian target market', Icons.visibility_rounded, const Color(0xFF4D2975), 1.0, '1,200 reach'),
        _buildFunnelStage('INTEREST', 'Membangun ketertarikan', Icons.favorite_rounded, const Color(0xFF0168FA), 0.75, '450 engaged'),
        _buildFunnelStage('DESIRE', 'Menciptakan keinginan', Icons.star_rounded, const Color(0xFFFF6F00), 0.55, '120 leads'),
        _buildFunnelStage('ACTION', 'Konversi jadi customer', Icons.shopping_bag_rounded, const Color(0xFF10B759), 0.35, '45 customers'),
        _buildFunnelStage('RETENTION', 'Menjaga loyalitas', Icons.repeat_rounded, const Color(0xFFDC3545), 0.25, '28 repeat'),
      ],
    );
  }

  Widget _buildFunnelStage(String label, String desc, IconData icon, Color color, double widthFactor, String metric) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: Text(desc, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Text(metric, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _strategyCard(String stage, List<String> items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stage, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  Expanded(child: Text(item, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.4))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
