import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/recruitment_widget.dart';

/// Tab Rekrutmen — pipeline + daftar pelamar.
class HrRecruitmentTab extends StatelessWidget {
  const HrRecruitmentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          const RecruitmentWidget(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildApplicantList(),
        ],
      ),
    );
  }

  Widget _buildApplicantList() {
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
                Text('Daftar Pelamar', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppDimensions.radiusS), border: Border.all(color: AppColors.divider)),
                  child: Text('13 pelamar', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ..._applicants.map((a) => _buildRow(a)),
        ],
      ),
    );
  }

  Widget _buildRow(_Applicant a) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: a.stageColor.withValues(alpha: 0.15), child: Text(a.name[0], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: a.stageColor))),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(a.position, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ])),
          Expanded(flex: 2, child: Text(a.source, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text(a.applyDate, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: a.stageColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusS)),
            child: Text(a.stage, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: a.stageColor)),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
            onSelected: (_) {},
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'view', child: Text('Lihat Detail')),
              const PopupMenuItem(value: 'advance', child: Text('Lanjutkan')),
              const PopupMenuItem(value: 'reject', child: Text('Tolak')),
            ],
          ),
        ],
      ),
    );
  }

  static const _applicants = [
    _Applicant('Indra Kusuma', 'Staff Marketing', 'LinkedIn', '10 Mar', 'Interview', Color(0xFFFF6F00)),
    _Applicant('Joko Widodo', 'Staff Marketing', 'Referral', '9 Mar', 'Interview', Color(0xFFFF6F00)),
    _Applicant('Kartika Sari', 'Staff Marketing', 'JobStreet', '8 Mar', 'Screening', Color(0xFF0168FA)),
    _Applicant('Lina Marlina', 'Staff Produksi', 'Walk-in', '12 Mar', 'Interview', Color(0xFFFF6F00)),
    _Applicant('Mega Putri', 'Staff Produksi', 'Instagram', '11 Mar', 'Screening', Color(0xFF0168FA)),
    _Applicant('Nanda Rahman', 'Staff Produksi', 'Referral', '10 Mar', 'Screening', Color(0xFF0168FA)),
    _Applicant('Omar Fauzi', 'Staff Produksi', 'JobStreet', '9 Mar', 'Applied', Color(0xFF4D2975)),
    _Applicant('Putri Amalia', 'Staff Marketing', 'LinkedIn', '8 Mar', 'Applied', Color(0xFF4D2975)),
    _Applicant('Qori Hidayat', 'Staff Produksi', 'Walk-in', '7 Mar', 'Screening', Color(0xFF0168FA)),
    _Applicant('Rina Salsabila', 'Staff Marketing', 'Instagram', '6 Mar', 'Applied', Color(0xFF4D2975)),
    _Applicant('Sandi Pratama', 'Staff Produksi', 'Referral', '5 Mar', 'Applied', Color(0xFF4D2975)),
    _Applicant('Tina Handayani', 'Staff Produksi', 'JobStreet', '4 Mar', 'Screening', Color(0xFF0168FA)),
    _Applicant('Umar Faruq', 'Staff Produksi', 'Walk-in', '3 Mar', 'Applied', Color(0xFF4D2975)),
  ];
}

class _Applicant {
  final String name;
  final String position;
  final String source;
  final String applyDate;
  final String stage;
  final Color stageColor;
  const _Applicant(this.name, this.position, this.source, this.applyDate, this.stage, this.stageColor);
}
