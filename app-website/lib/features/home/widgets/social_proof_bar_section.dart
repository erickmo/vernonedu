import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// Section 2: Social Proof Bar — statistik live dari API dalam satu baris.
class SocialProofBarSection extends StatelessWidget {
  const SocialProofBarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final isMobile = Responsive.isMobile(context);
        final padH = Responsive.sectionPaddingH(context);

        int students = 5000, courses = 50, partners = 100, branches = 10;
        if (state is HomeLoaded) {
          final s = state.stats;
          if (s.students > 0) students = s.students;
          if (s.courses > 0) courses = s.courses;
          if (s.partners > 0) partners = s.partners;
          if (s.branches > 0) branches = s.branches;
        }

        final items = [
          _ProofItem(
            icon: Icons.people_rounded,
            value: '$students+',
            label: 'Siswa Aktif',
            color: AppColors.brandPurple,
          ),
          _ProofItem(
            icon: Icons.business_rounded,
            value: '$partners+',
            label: 'Perusahaan Partner',
            color: AppColors.brandBlue,
          ),
          _ProofItem(
            icon: Icons.auto_stories_rounded,
            value: '$courses+',
            label: 'Kursus Tersedia',
            color: AppColors.brandGreen,
          ),
          _ProofItem(
            icon: Icons.location_city_rounded,
            value: '$branches cabang',
            label: 'Lokasi VernonEdu',
            color: AppColors.brandOrange,
          ),
        ];

        return Container(
          color: AppColors.bgDarkSection,
          padding: EdgeInsets.symmetric(
            horizontal: padH,
            vertical: AppDimensions.s32,
          ),
          child: isMobile
              ? _MobileBar(items: items)
              : _DesktopBar(items: items),
        ).animate().fadeIn(duration: 600.ms);
      },
    );
  }
}

class _DesktopBar extends StatelessWidget {
  final List<_ProofItem> items;
  const _DesktopBar({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: _ProofItemWidget(item: item, index: i)),
              if (i < items.length - 1)
                Container(
                  width: 1,
                  height: 48,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MobileBar extends StatelessWidget {
  final List<_ProofItem> items;
  const _MobileBar({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: AppDimensions.s16,
      crossAxisSpacing: AppDimensions.s16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.4,
      children: items
          .asMap()
          .entries
          .map((e) => _ProofItemWidget(item: e.value, index: e.key))
          .toList(),
    );
  }
}

class _ProofItemWidget extends StatelessWidget {
  final _ProofItem item;
  final int index;

  const _ProofItemWidget({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(item.icon, color: item.color, size: 20),
        ),
        const SizedBox(width: AppDimensions.s12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.value,
              style: AppTextStyles.h3OnDark.copyWith(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              item.label,
              style: AppTextStyles.bodyXS.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    )
        .animate(delay: (index * 100).ms)
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.15, end: 0);
  }
}

class _ProofItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ProofItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}
