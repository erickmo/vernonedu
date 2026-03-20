import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class _Employee {
  final String name;
  final String role;
  final String division;
  final Color divColor;
  final String joinDate;
  final String status;
  final Color statusColor;

  const _Employee(this.name, this.role, this.division, this.divColor, this.joinDate, this.status, this.statusColor);
}

/// Daftar karyawan / anggota tim.
class EmployeeListWidget extends StatelessWidget {
  const EmployeeListWidget({super.key});

  static const _employees = [
    _Employee('Ahmad Rizky', 'Staff Produksi', 'Operasional', Color(0xFF0168FA), '1 Jan 2026', 'Active', AppColors.success),
    _Employee('Budi Santoso', 'Staff Logistik', 'Operasional', Color(0xFF0168FA), '1 Jan 2026', 'Active', AppColors.success),
    _Employee('Citra Dewi', 'Social Media Specialist', 'Marketing', Color(0xFF10B759), '15 Jan 2026', 'Active', AppColors.success),
    _Employee('Dina Aulia', 'Content Creator', 'Marketing', Color(0xFF10B759), '1 Feb 2026', 'Active', AppColors.success),
    _Employee('Eka Putri', 'Accounting', 'Finance', Color(0xFFFF6F00), '1 Jan 2026', 'Active', AppColors.success),
    _Employee('Fani Rahayu', 'Admin', 'Finance', Color(0xFFFF6F00), '15 Feb 2026', 'Active', AppColors.success),
    _Employee('Gilang Pratama', 'Intern', 'Marketing', Color(0xFF10B759), '1 Mar 2026', 'Probation', Color(0xFFFF6F00)),
    _Employee('Hana Safitri', 'Intern', 'Operasional', Color(0xFF0168FA), '1 Mar 2026', 'Probation', Color(0xFFFF6F00)),
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
                Text('Daftar Anggota Tim', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: Text('Tambah Anggota', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._employees.map((e) => _buildRow(e)),
        ],
      ),
    );
  }

  Widget _buildRow(_Employee e) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: e.divColor.withValues(alpha: 0.15),
            child: Text(e.name[0], style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: e.divColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(e.role, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: e.divColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
              child: Text(e.division, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: e.divColor), textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          SizedBox(
            width: 70,
            child: Text(e.joinDate, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: e.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Text(e.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: e.statusColor)),
          ),
        ],
      ),
    );
  }
}
