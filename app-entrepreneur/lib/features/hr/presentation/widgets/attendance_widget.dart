import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class _AttendanceRow {
  final String name;
  final String time;
  final String status;
  final Color statusColor;
  const _AttendanceRow(this.name, this.time, this.status, this.statusColor);
}

/// Kehadiran hari ini — daftar check-in anggota tim.
class AttendanceWidget extends StatelessWidget {
  const AttendanceWidget({super.key});

  static const _rows = [
    _AttendanceRow('Ahmad Rizky', '08:05', 'On Time', AppColors.success),
    _AttendanceRow('Budi Santoso', '08:12', 'On Time', AppColors.success),
    _AttendanceRow('Citra Dewi', '08:30', 'On Time', AppColors.success),
    _AttendanceRow('Dina Aulia', '09:15', 'Late', Color(0xFFFF6F00)),
    _AttendanceRow('Eka Putri', '08:00', 'On Time', AppColors.success),
    _AttendanceRow('Fani Rahayu', '08:22', 'On Time', AppColors.success),
    _AttendanceRow('Gilang Pratama', '-', 'Absent', AppColors.error),
    _AttendanceRow('Hana Safitri', '-', 'Izin', AppColors.info),
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
                const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Kehadiran Hari Ini', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Summary
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                _miniStat('Hadir', '6', AppColors.success),
                const SizedBox(width: AppDimensions.spacingM),
                _miniStat('Telat', '1', const Color(0xFFFF6F00)),
                const SizedBox(width: AppDimensions.spacingM),
                _miniStat('Absent', '1', AppColors.error),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._rows.map((r) => _buildRow(r)),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_AttendanceRow r) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: r.statusColor.withValues(alpha: 0.15),
            child: Text(r.name[0], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: r.statusColor)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(r.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
          SizedBox(width: 45, child: Text(r.time, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(color: r.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Text(r.status, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: r.statusColor), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
