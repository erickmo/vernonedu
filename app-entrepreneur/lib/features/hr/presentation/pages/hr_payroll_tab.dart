import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/payroll_widget.dart';

/// Tab Payroll — summary + detail per anggota.
class HrPayrollTab extends StatelessWidget {
  const HrPayrollTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          if (isDesktop)
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: PayrollWidget()),
                SizedBox(width: AppDimensions.spacingL),
                Expanded(flex: 6, child: _PayrollDetailTable()),
              ],
            )
          else ...[
            const PayrollWidget(),
            const SizedBox(height: AppDimensions.spacingL),
            const _PayrollDetailTable(),
          ],
        ],
      ),
    );
  }
}

class _PayrollDetail {
  final String name;
  final String role;
  final int gajiPokok;
  final int tunjangan;
  final int bonus;
  final int potongan;
  final String status;
  final Color statusColor;

  const _PayrollDetail(this.name, this.role, this.gajiPokok, this.tunjangan, this.bonus, this.potongan, this.status, this.statusColor);

  int get totalBersih => gajiPokok + tunjangan + bonus - potongan;
}

class _PayrollDetailTable extends StatelessWidget {
  const _PayrollDetailTable();

  static const _data = [
    _PayrollDetail('Ahmad Rizky', 'Produksi', 500000, 60000, 50000, 25000, 'Paid', AppColors.success),
    _PayrollDetail('Budi Santoso', 'Logistik', 500000, 60000, 40000, 20000, 'Paid', AppColors.success),
    _PayrollDetail('Citra Dewi', 'Social Media', 450000, 60000, 50000, 20000, 'Paid', AppColors.success),
    _PayrollDetail('Dina Aulia', 'Content', 450000, 60000, 30000, 15000, 'Paid', AppColors.success),
    _PayrollDetail('Eka Putri', 'Accounting', 400000, 60000, 40000, 20000, 'Pending', Color(0xFFFF6F00)),
    _PayrollDetail('Fani Rahayu', 'Admin', 400000, 60000, 30000, 20000, 'Pending', Color(0xFFFF6F00)),
    _PayrollDetail('Gilang Pratama', 'Intern', 250000, 60000, 40000, 20000, 'Draft', AppColors.textMuted),
    _PayrollDetail('Hana Safitri', 'Intern', 250000, 60000, 40000, 20000, 'Draft', AppColors.textMuted),
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
                Text('Detail Payroll per Anggota', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text('Export', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._data.map((d) => _buildRow(d)),
        ],
      ),
    );
  }

  Widget _buildRow(_PayrollDetail d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: AppColors.primary.withValues(alpha: 0.15), child: Text(d.name[0], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(d.role, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
          ])),
          Expanded(flex: 2, child: Text(_fmt(d.gajiPokok), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.right)),
          Expanded(flex: 2, child: Text(_fmt(d.totalBersih), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.right)),
          const SizedBox(width: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: d.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Text(d.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: d.statusColor)),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return 'Rp ${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return 'Rp ${(n / 1000).toStringAsFixed(0)}K';
    return 'Rp $n';
  }
}
