import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class _OpenPosition {
  final String title;
  final String division;
  final Color divColor;
  final int applicants;
  final String status;
  final Color statusColor;
  const _OpenPosition(this.title, this.division, this.divColor, this.applicants, this.status, this.statusColor);
}

/// Open positions & recruitment pipeline.
class RecruitmentWidget extends StatelessWidget {
  const RecruitmentWidget({super.key});

  static const _positions = [
    _OpenPosition('Staff Marketing', 'Marketing', Color(0xFF10B759), 5, 'Interviewing', AppColors.info),
    _OpenPosition('Staff Produksi', 'Operasional', Color(0xFF0168FA), 8, 'Open', Color(0xFF10B759)),
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
            child: Row(
              children: [
                const Icon(Icons.person_search_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Rekrutmen', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: Text('Buka Posisi', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Pipeline summary
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                _pipelineStep('Applied', '13', const Color(0xFF4D2975)),
                _pipelineArrow(),
                _pipelineStep('Screening', '8', const Color(0xFF0168FA)),
                _pipelineArrow(),
                _pipelineStep('Interview', '3', const Color(0xFFFF6F00)),
                _pipelineArrow(),
                _pipelineStep('Hired', '0', const Color(0xFF10B759)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Open positions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: AppDimensions.spacingS),
            child: Text('Open Positions', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLabel)),
          ),
          ..._positions.map((p) => _buildPositionRow(p)),
          const SizedBox(height: AppDimensions.spacingS),
        ],
      ),
    );
  }

  Widget _pipelineStep(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Column(
          children: [
            Text(count, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _pipelineArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textMuted),
    );
  }

  Widget _buildPositionRow(_OpenPosition p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: p.divColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
                        child: Text(p.division, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: p.divColor)),
                      ),
                      const SizedBox(width: 8),
                      Text('${p.applicants} pelamar', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: p.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
              child: Text(p.status, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: p.statusColor)),
            ),
          ],
        ),
      ),
    );
  }
}
