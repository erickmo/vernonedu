import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class _ContentItem {
  final String title;
  final String channel;
  final IconData channelIcon;
  final Color channelColor;
  final String type;
  final String date;
  final String status;
  final Color statusColor;

  const _ContentItem(this.title, this.channel, this.channelIcon, this.channelColor, this.type, this.date, this.status, this.statusColor);
}

/// Content calendar — jadwal konten marketing.
class ContentCalendarWidget extends StatelessWidget {
  const ContentCalendarWidget({super.key});

  static const _items = [
    _ContentItem('5 Tips Memulai Bisnis Pertama', 'Instagram', Icons.camera_alt_rounded, Color(0xFFE4405F), 'Carousel', '17 Mar', 'Scheduled', AppColors.info),
    _ContentItem('Behind The Scene - Produksi', 'TikTok', Icons.music_note_rounded, Color(0xFF000000), 'Video', '18 Mar', 'Draft', AppColors.textMuted),
    _ContentItem('Promo Spesial Minggu Ini', 'Instagram', Icons.camera_alt_rounded, Color(0xFFE4405F), 'Story', '18 Mar', 'Scheduled', AppColors.info),
    _ContentItem('Newsletter: Update Produk Baru', 'Email', Icons.mail_rounded, Color(0xFF0168FA), 'Email', '19 Mar', 'Draft', AppColors.textMuted),
    _ContentItem('Testimoni Customer: Pak Budi', 'TikTok', Icons.music_note_rounded, Color(0xFF000000), 'Video', '20 Mar', 'Idea', Color(0xFFFF6F00)),
    _ContentItem('Flash Sale Announcement', 'WhatsApp', Icons.chat_rounded, Color(0xFF25D366), 'Broadcast', '21 Mar', 'Scheduled', AppColors.info),
    _ContentItem('Tips Marketing untuk UMKM', 'Instagram', Icons.camera_alt_rounded, Color(0xFFE4405F), 'Reels', '22 Mar', 'Idea', Color(0xFFFF6F00)),
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
                const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Content Calendar', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusS), border: Border.all(color: AppColors.divider)),
                  child: Text('Minggu ini', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text('Tambah', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._items.map((item) => _buildRow(item)),
        ],
      ),
    );
  }

  Widget _buildRow(_ContentItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(item.date, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLabel)),
          ),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: item.channelColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Icon(item.channelIcon, color: item.channelColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Text(item.channel, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                    Text(' • ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                    Text(item.type, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: item.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Text(item.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: item.statusColor)),
          ),
        ],
      ),
    );
  }
}
