import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class _Campaign {
  final String name;
  final String channel;
  final String status;
  final Color statusColor;
  final String budget;
  final String reach;
  final String conversion;
  final String period;

  const _Campaign(this.name, this.channel, this.status, this.statusColor, this.budget, this.reach, this.conversion, this.period);
}

/// Daftar campaign marketing.
class CampaignListWidget extends StatelessWidget {
  const CampaignListWidget({super.key});

  static const _campaigns = [
    _Campaign('Launch Promo 50%', 'Instagram', 'Active', AppColors.success, 'Rp 500K', '820', '4.2%', '1-15 Mar'),
    _Campaign('Content Series: Tips Bisnis', 'TikTok', 'Active', AppColors.success, 'Rp 200K', '2.1K', '2.8%', '1-31 Mar'),
    _Campaign('Email Welcome Series', 'Email', 'Active', AppColors.success, 'Rp 0', '150', '12%', 'Ongoing'),
    _Campaign('Referral Program', 'WhatsApp', 'Draft', AppColors.textMuted, 'Rp 300K', '-', '-', 'Planned'),
    _Campaign('Google Ads - Brand', 'Google', 'Paused', Color(0xFFFF6F00), 'Rp 1M', '3.5K', '1.5%', '1-10 Mar'),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                Text('Campaigns', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Buat Campaign', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._campaigns.map((c) => _buildRow(c)),
        ],
      ),
    );
  }

  Widget _buildRow(_Campaign c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _channelIcon(c.channel),
                    const SizedBox(width: 4),
                    Text(c.channel, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Text(c.period, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          _metricCol('Budget', c.budget),
          _metricCol('Reach', c.reach),
          _metricCol('Conv.', c.conversion),
          const SizedBox(width: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: c.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Text(c.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: c.statusColor)),
          ),
        ],
      ),
    );
  }

  Widget _metricCol(String label, String value) {
    return SizedBox(
      width: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _channelIcon(String channel) {
    final IconData icon;
    switch (channel) {
      case 'Instagram': icon = Icons.camera_alt_rounded;
      case 'TikTok': icon = Icons.music_note_rounded;
      case 'Email': icon = Icons.mail_rounded;
      case 'WhatsApp': icon = Icons.chat_rounded;
      case 'Google': icon = Icons.search_rounded;
      default: icon = Icons.language_rounded;
    }
    return Icon(icon, size: 14, color: AppColors.textMuted);
  }
}
