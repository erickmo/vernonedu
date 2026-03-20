import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class _ChannelData {
  final String name;
  final IconData icon;
  final Color color;
  final int followers;
  final double engagement;
  final double growth;

  const _ChannelData(this.name, this.icon, this.color, this.followers, this.engagement, this.growth);
}

/// Performa per channel marketing.
class ChannelPerformanceWidget extends StatelessWidget {
  const ChannelPerformanceWidget({super.key});

  static const _channels = [
    _ChannelData('Instagram', Icons.camera_alt_rounded, Color(0xFFE4405F), 850, 4.2, 12.5),
    _ChannelData('TikTok', Icons.music_note_rounded, Color(0xFF000000), 1200, 6.8, 25.0),
    _ChannelData('WhatsApp', Icons.chat_rounded, Color(0xFF25D366), 200, 0, 5.0),
    _ChannelData('Website', Icons.language_rounded, Color(0xFF0168FA), 0, 2.1, 8.0),
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
            child: Text('Channel Performance', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._channels.map((ch) => _buildChannelRow(ch)),
        ],
      ),
    );
  }

  Widget _buildChannelRow(_ChannelData ch) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: ch.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Icon(ch.icon, color: ch.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ch.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Row(
                  children: [
                    if (ch.followers > 0)
                      Text('${ch.followers} followers', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                    if (ch.followers > 0 && ch.engagement > 0)
                      Text(' • ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                    if (ch.engagement > 0)
                      Text('${ch.engagement}% eng.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up_rounded, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text('+${ch.growth}%', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
