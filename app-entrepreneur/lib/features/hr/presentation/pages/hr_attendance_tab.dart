import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/attendance_widget.dart';

/// Tab Kehadiran — attendance hari ini + rekap bulanan.
class HrAttendanceTab extends StatelessWidget {
  const HrAttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 5, child: AttendanceWidget()),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(flex: 5, child: _buildMonthlyRecap()),
              ],
            )
          else ...[
            const AttendanceWidget(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildMonthlyRecap(),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyRecap() {
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
                const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Rekap Kehadiran — Maret 2026', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._monthlyData.map((d) => _buildMonthlyRow(d)),
        ],
      ),
    );
  }

  Widget _buildMonthlyRow(_MonthlyAttendance d) {
    final totalDays = d.onTime + d.late + d.absent + d.izin;
    final attendRate = totalDays > 0 ? ((d.onTime + d.late) / totalDays * 100).toInt() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(d.name[0], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(d.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
          _miniCount('${d.onTime}', AppColors.success),
          _miniCount('${d.late}', const Color(0xFFFF6F00)),
          _miniCount('${d.absent}', AppColors.error),
          _miniCount('${d.izin}', AppColors.info),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text('$attendRate%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: attendRate >= 80 ? AppColors.success : AppColors.error), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _miniCount(String value, Color color) {
    return Container(
      width: 28, height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      alignment: Alignment.center,
      child: Text(value, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  static const _monthlyData = [
    _MonthlyAttendance('Ahmad Rizky', 12, 0, 0, 0),
    _MonthlyAttendance('Budi Santoso', 11, 1, 0, 0),
    _MonthlyAttendance('Citra Dewi', 10, 1, 0, 1),
    _MonthlyAttendance('Dina Aulia', 9, 2, 1, 0),
    _MonthlyAttendance('Eka Putri', 12, 0, 0, 0),
    _MonthlyAttendance('Fani Rahayu', 11, 0, 0, 1),
    _MonthlyAttendance('Gilang Pratama', 8, 2, 1, 1),
    _MonthlyAttendance('Hana Safitri', 9, 1, 1, 1),
  ];
}

class _MonthlyAttendance {
  final String name;
  final int onTime;
  final int late;
  final int absent;
  final int izin;
  const _MonthlyAttendance(this.name, this.onTime, this.late, this.absent, this.izin);
}
