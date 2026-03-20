import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Practicum section — link ke Business Ideation untuk praktek langsung.
class PracticumSectionWidget extends StatelessWidget {
  final VoidCallback onStartPracticum;

  const PracticumSectionWidget({
    super.key,
    required this.onStartPracticum,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Row(
              children: [
                const Icon(Icons.science_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'Praktikum',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terapkan ilmu yang sudah kamu pelajari dengan membuat bisnis nyata!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildPracticumItem(
                  step: '1',
                  title: 'PESTEL Analysis',
                  description:
                      'Analisis faktor Political, Economic, Social, Technological, Environmental, Legal',
                ),
                _buildPracticumItem(
                  step: '2',
                  title: 'Design Thinking',
                  description:
                      'Empathize, Define, Ideate, Prototype, Test — framework inovasi',
                ),
                _buildPracticumItem(
                  step: '3',
                  title: 'Value Proposition Canvas',
                  description:
                      'Pemetaan customer profile dan value map produk/jasa kamu',
                ),
                _buildPracticumItem(
                  step: '4',
                  title: 'Business Model Canvas',
                  description:
                      '9 building blocks untuk merancang model bisnis yang viable',
                ),
                _buildPracticumItem(
                  step: '5',
                  title: 'Flywheel Marketing',
                  description:
                      'Strategi marketing berkelanjutan: Attract, Engage, Delight',
                  isLast: true,
                ),
                const SizedBox(height: AppDimensions.spacingL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStartPracticum,
                    icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                    label: Text(
                      'Mulai Praktikum — Business Ideation',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticumItem({
    required String step,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                ),
                alignment: Alignment.center,
                child: Text(
                  step,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 30,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
