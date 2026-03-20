import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'hr_overview_tab.dart';
import 'hr_employee_tab.dart';
import 'hr_attendance_tab.dart';
import 'hr_payroll_tab.dart';
import 'hr_recruitment_tab.dart';

/// HR Management page — tab-based layout.
class HrPage extends StatefulWidget {
  const HrPage({super.key});

  @override
  State<HrPage> createState() => _HrPageState();
}

class _HrPageState extends State<HrPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: 'Overview'),
    Tab(text: 'Anggota Tim'),
    Tab(text: 'Kehadiran'),
    Tab(text: 'Payroll'),
    Tab(text: 'Rekrutmen'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.spacingL, AppDimensions.spacingL, AppDimensions.spacingL, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HR Management', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: AppDimensions.spacingXS),
              Text('Kelola tim, kehadiran, penggajian, dan rekrutmen.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
          child: TabBar(
            controller: _tabController,
            tabs: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              HrOverviewTab(),
              HrEmployeeTab(),
              HrAttendanceTab(),
              HrPayrollTab(),
              HrRecruitmentTab(),
            ],
          ),
        ),
      ],
    );
  }
}
