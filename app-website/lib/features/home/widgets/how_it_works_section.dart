import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/scroll_animate_widget.dart';
import '../../../core/widgets/section_header.dart';

/// Cara Kerja VernonEdu — 4 langkah dengan visual timeline.
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  static const _steps = [
    _Step(
      number: '01',
      icon: Icons.search_rounded,
      title: 'Pilih Kursus',
      description: 'Browse katalog 50+ kursus dan temukan program yang paling sesuai dengan tujuan karirmu.',
      color: AppColors.brandIndigo,
    ),
    _Step(
      number: '02',
      icon: Icons.credit_card_rounded,
      title: 'Daftar & Bayar',
      description: 'Pendaftaran mudah dengan 5 metode pembayaran fleksibel — cicilan, per-sesi, atau sekaligus.',
      color: AppColors.brandGreen,
    ),
    _Step(
      number: '03',
      icon: Icons.emoji_events_rounded,
      title: 'Belajar & Raih Sertifikat',
      description: 'Ikuti kursus bersama instruktur ahli, selesaikan modul, dan dapatkan sertifikat resmi diakui industri.',
      color: AppColors.brandGold,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padH = Responsive.sectionPaddingH(context);
    final padV = Responsive.sectionPaddingV(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      child: Column(
        children: [
          ScrollAnimateWidget(
            uniqueKey: 'how_header',
            child: const SectionHeader(
              badge: '🚀 Cara Memulai',
              title: 'Mulai dalam 3 Langkah\nSederhana',
              subtitle:
                  'Dari pilih kursus hingga raih sertifikat — prosesnya mudah dan terstruktur.',
            ),
          ),

          const SizedBox(height: AppDimensions.s64),

          isMobile ? _MobileSteps(steps: _steps) : _DesktopSteps(steps: _steps),
        ],
      ),
    );
  }
}

class _DesktopSteps extends StatelessWidget {
  final List<_Step> steps;

  const _DesktopSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        return Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StepCard(step: step, index: i)),
              if (i < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: _StepConnector(color: steps[i + 1].color),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MobileSteps extends StatelessWidget {
  final List<_Step> steps;

  const _MobileSteps({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        return Column(
          children: [
            _MobileStepItem(step: step, index: i),
            if (i < steps.length - 1)
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.only(left: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [step.color, steps[i + 1].color],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                alignment: Alignment.centerLeft,
              ),
          ],
        );
      }).toList(),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _Step step;
  final int index;

  const _StepCard({required this.step, required this.index});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Number circle
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                step.color.withValues(alpha: 0.2),
                step.color.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: step.color.withValues(alpha: 0.4), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(step.icon, color: step.color, size: 28),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.s20),

        // Step number
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: step.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'LANGKAH ${step.number}',
            style: AppTextStyles.badge.copyWith(color: step.color, fontSize: 10),
          ),
        ),

        const SizedBox(height: AppDimensions.s12),

        Text(
          step.title,
          style: AppTextStyles.h4,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppDimensions.s8),

        Text(
          step.description,
          style: AppTextStyles.bodyS,
          textAlign: TextAlign.center,
          maxLines: 4,
        ),
      ],
    )
        .animate(delay: (index * 150).ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }
}

class _MobileStepItem extends StatelessWidget {
  final _Step step;
  final int index;

  const _MobileStepItem({required this.step, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left — icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [step.color.withValues(alpha: 0.25), step.color.withValues(alpha: 0.08)],
            ),
            border: Border.all(color: step.color.withValues(alpha: 0.4)),
          ),
          child: Icon(step.icon, color: step.color, size: 22),
        ),

        const SizedBox(width: AppDimensions.s16),

        // Right — text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LANGKAH ${step.number}',
                style: AppTextStyles.badge.copyWith(color: step.color, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Text(step.title, style: AppTextStyles.h4),
              const SizedBox(height: 6),
              Text(step.description, style: AppTextStyles.bodyS, maxLines: 3),
            ],
          ),
        ),
      ],
    )
        .animate(delay: (index * 120).ms)
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.2, end: 0);
  }
}

/// Connector arrow antara step (desktop).
class _StepConnector extends StatelessWidget {
  final Color color;

  const _StepConnector({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: color.withValues(alpha: 0.4),
        size: 20,
      ),
    );
  }
}

class _Step {
  final String number;
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _Step({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
