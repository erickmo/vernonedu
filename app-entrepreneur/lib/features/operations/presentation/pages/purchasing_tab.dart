import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../widgets/purchase_stats_widget.dart';
import '../widgets/purchase_flow_widget.dart';
import '../widgets/purchase_list_widget.dart';

/// Tab Pembelian — statistik, flow diagram, dan daftar dokumen.
class PurchasingTab extends StatelessWidget {
  const PurchasingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PurchaseStatsWidget(),
          SizedBox(height: AppDimensions.spacingL),
          PurchaseFlowWidget(),
          SizedBox(height: AppDimensions.spacingL),
          PurchaseListWidget(),
        ],
      ),
    );
  }
}
