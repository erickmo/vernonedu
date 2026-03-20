import 'package:flutter/widgets.dart';
import '../constants/app_dimensions.dart';

/// Helper untuk responsive layout.
class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppDimensions.mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= AppDimensions.mobileBreakpoint &&
        w < AppDimensions.desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppDimensions.desktopBreakpoint;

  /// Padding horizontal yang otomatis menjaga konten max 1200px di center.
  /// Background section tetap full-width, hanya inner content yang dibatasi.
  static double sectionPaddingH(BuildContext context) {
    if (isMobile(context)) return AppDimensions.sectionPaddingHMobile;
    final screenWidth = MediaQuery.of(context).size.width;
    const maxContent = AppDimensions.maxContentWidth;
    const minPadding = AppDimensions.sectionPaddingH;
    if (screenWidth > maxContent + minPadding * 2) {
      return (screenWidth - maxContent) / 2;
    }
    return minPadding;
  }

  static double sectionPaddingV(BuildContext context) =>
      isMobile(context)
          ? AppDimensions.sectionPaddingVMobile
          : AppDimensions.sectionPaddingV;
}
