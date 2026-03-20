import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../widgets/content_calendar_widget.dart';

/// Tab Content — content calendar full view.
class MarketingContentTab extends StatelessWidget {
  const MarketingContentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: ContentCalendarWidget(),
    );
  }
}
