import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/org_chart_widget.dart';
import '../widgets/attendance_widget.dart';
import '../widgets/payroll_widget.dart';
import '../widgets/recruitment_widget.dart';

/// Tab Overview — stats, org chart, ringkasan attendance/payroll/recruitment.
class HrOverviewTab extends StatelessWidget {
  const HrOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStats(context),
          const SizedBox(height: AppDimensions.spacingL),
          const OrgChartWidget(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildMiddleSection(context),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    final isTablet = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointMobile;
    final cross = isDesktop ? 4 : (isTablet ? 2 : 1);

    return GridView.count(
      crossAxisCount: cross, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spacingM, crossAxisSpacing: AppDimensions.spacingM,
      childAspectRatio: isDesktop ? 2.2 : (isTablet ? 2.0 : 3.0),
      children: const [
        _StatCard(Icons.people_rounded, Color(0xFF4D2975), '8', 'Total Anggota'),
        _StatCard(Icons.check_circle_rounded, Color(0xFF10B759), '6', 'Hadir Hari Ini'),
        _StatCard(Icons.work_rounded, Color(0xFF0168FA), '3', 'Divisi'),
        _StatCard(Icons.person_search_rounded, Color(0xFFFF6F00), '2', 'Open Position'),
      ],
    );
  }

  Widget _buildMiddleSection(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;
    if (isDesktop) {
      return const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 4, child: AttendanceWidget()),
        SizedBox(width: AppDimensions.spacingL),
        Expanded(flex: 3, child: PayrollWidget()),
        SizedBox(width: AppDimensions.spacingL),
        Expanded(flex: 3, child: RecruitmentWidget()),
      ]);
    }
    return const Column(children: [
      AttendanceWidget(), SizedBox(height: AppDimensions.spacingL),
      PayrollWidget(), SizedBox(height: AppDimensions.spacingL),
      RecruitmentWidget(),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final Color color; final String value; final String sub;
  const _StatCard(this.icon, this.color, this.value, this.sub);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimensions.radiusM), border: Border.all(color: AppColors.divider.withValues(alpha: 0.5))),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusM)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
        ])),
      ]),
    );
  }
}
