import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class BmcPage extends StatelessWidget {
  const BmcPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppDimensions.lg),
          _buildComingSoon(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Text(
        'Business Model Canvas',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
      );

  Widget _buildComingSoon(BuildContext context) => Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.grid_view_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: AppDimensions.md),
              Text(
                'Business Model Canvas akan segera hadir',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                '9 komponen BMC dengan tracking partner aktif secara langsung',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      );
}
