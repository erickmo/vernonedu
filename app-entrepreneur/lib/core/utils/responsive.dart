import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';

enum ScreenType { mobile, tablet, desktop }

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppDimensions.breakpointMobile) return ScreenType.mobile;
    if (width < AppDimensions.breakpointDesktop) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppDimensions.breakpointMobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppDimensions.breakpointMobile &&
        width < AppDimensions.breakpointDesktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;

  @override
  Widget build(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.desktop:
        return desktop;
      case ScreenType.tablet:
        return tablet ?? desktop;
      case ScreenType.mobile:
        return mobile;
    }
  }
}
