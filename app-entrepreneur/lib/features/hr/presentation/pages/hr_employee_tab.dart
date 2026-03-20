import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../widgets/org_chart_widget.dart';
import '../widgets/employee_list_widget.dart';

/// Tab Anggota Tim — org chart + daftar lengkap.
class HrEmployeeTab extends StatelessWidget {
  const HrEmployeeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          OrgChartWidget(),
          SizedBox(height: AppDimensions.spacingL),
          EmployeeListWidget(),
        ],
      ),
    );
  }
}
