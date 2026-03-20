import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../widgets/campaign_list_widget.dart';
import '../widgets/marketing_funnel_widget.dart';

/// Tab Campaigns — funnel + full campaign list.
class MarketingCampaignTab extends StatelessWidget {
  const MarketingCampaignTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          MarketingFunnelWidget(),
          SizedBox(height: AppDimensions.spacingL),
          CampaignListWidget(),
        ],
      ),
    );
  }
}
