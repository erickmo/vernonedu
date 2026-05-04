import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class InitialAvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final double fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;

  const InitialAvatarWidget({
    super.key,
    required this.name,
    this.size = 38,
    this.fontSize = 18,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = AppDimensions.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primarySurface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: textColor ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}
