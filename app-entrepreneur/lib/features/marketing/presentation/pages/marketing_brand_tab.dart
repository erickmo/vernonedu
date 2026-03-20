import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../widgets/brand_identity_widget.dart';

/// Tab Branding — brand identity full view.
class MarketingBrandTab extends StatelessWidget {
  const MarketingBrandTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.spacingL),
      child: BrandIdentityWidget(),
    );
  }
}
