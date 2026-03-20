import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Announcement data model.
class Announcement {
  final String title;
  final String message;
  final AnnouncementType type;
  final DateTime date;

  const Announcement({
    required this.title,
    required this.message,
    required this.type,
    required this.date,
  });
}

enum AnnouncementType { info, warning, success, urgent }

/// Dashboard announcement banner — tampil jika ada announcement aktif.
class AnnouncementWidget extends StatefulWidget {
  const AnnouncementWidget({super.key});

  @override
  State<AnnouncementWidget> createState() => _AnnouncementWidgetState();
}

class _AnnouncementWidgetState extends State<AnnouncementWidget> {
  // TODO: replace with data from API/Cubit
  final List<Announcement> _announcements = [
    Announcement(
      title: 'Pitch Day Competition',
      message:
          'Pitch Day akan diadakan pada 25 Maret 2026. Pastikan Business Model Canvas kamu sudah lengkap sebelum deadline!',
      type: AnnouncementType.urgent,
      date: DateTime(2026, 3, 16),
    ),
    Announcement(
      title: 'Modul Baru Tersedia',
      message:
          'Modul "Digital Marketing Strategy" sudah tersedia di Learning. Mulai belajar sekarang!',
      type: AnnouncementType.info,
      date: DateTime(2026, 3, 15),
    ),
  ];

  final Set<int> _dismissed = {};

  @override
  Widget build(BuildContext context) {
    final visible = _announcements
        .asMap()
        .entries
        .where((e) => !_dismissed.contains(e.key))
        .toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      children: visible.map((entry) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: entry.key == visible.last.key ? 0 : AppDimensions.spacingS,
          ),
          child: _buildAnnouncementCard(entry.key, entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildAnnouncementCard(int index, Announcement announcement) {
    final config = _getTypeConfig(announcement.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: config.iconBgColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(config.icon, color: config.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: config.iconColor.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Text(
                        config.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: config.iconColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(announcement.date),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  announcement.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          InkWell(
            onTap: () => setState(() => _dismissed.add(index)),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  _AnnouncementTypeConfig _getTypeConfig(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.urgent:
        return _AnnouncementTypeConfig(
          label: 'URGENT',
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.error,
          iconBgColor: AppColors.error.withValues(alpha: 0.1),
          bgColor: const Color(0xFFFFF5F5),
          borderColor: AppColors.error.withValues(alpha: 0.2),
        );
      case AnnouncementType.warning:
        return _AnnouncementTypeConfig(
          label: 'WARNING',
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.warning,
          iconBgColor: AppColors.warning.withValues(alpha: 0.1),
          bgColor: const Color(0xFFFFFBF0),
          borderColor: AppColors.warning.withValues(alpha: 0.2),
        );
      case AnnouncementType.success:
        return _AnnouncementTypeConfig(
          label: 'SUCCESS',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.success,
          iconBgColor: AppColors.success.withValues(alpha: 0.1),
          bgColor: const Color(0xFFF0FFF4),
          borderColor: AppColors.success.withValues(alpha: 0.2),
        );
      case AnnouncementType.info:
        return _AnnouncementTypeConfig(
          label: 'INFO',
          icon: Icons.campaign_rounded,
          iconColor: AppColors.info,
          iconBgColor: AppColors.info.withValues(alpha: 0.1),
          bgColor: const Color(0xFFF0F7FF),
          borderColor: AppColors.info.withValues(alpha: 0.2),
        );
    }
  }
}

class _AnnouncementTypeConfig {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color bgColor;
  final Color borderColor;

  const _AnnouncementTypeConfig({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.bgColor,
    required this.borderColor,
  });
}
