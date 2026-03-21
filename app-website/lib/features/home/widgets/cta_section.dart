import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/scroll_animate_widget.dart';

/// CTA Section — dark purple banner (mengikuti brand VernonEdu).
class CtaSection extends StatelessWidget {
  const CtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padH = Responsive.sectionPaddingH(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: AppDimensions.s64),
      child: ScrollAnimateWidget(
        uniqueKey: 'cta_main',
        child: Container(
          padding: EdgeInsets.all(isMobile ? AppDimensions.s32 : AppDimensions.s64),
          decoration: BoxDecoration(
            // Dark purple seperti brand VernonEdu
            gradient: const LinearGradient(
              colors: [Color(0xFF3D2068), Color(0xFF5B3A9A), Color(0xFF7C68EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.r24),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPurple.withValues(alpha: 0.3),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.r24),
                  child: CustomPaint(painter: _CtaPatternPainter()),
                ),
              ),
              isMobile ? _MobileCtaContent() : _DesktopCtaContent(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopCtaContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 6, child: _CtaText()),
        const SizedBox(width: AppDimensions.s48),
        Expanded(flex: 4, child: _CtaStats()),
      ],
    );
  }
}

class _MobileCtaContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CtaText(centered: true),
        const SizedBox(height: AppDimensions.s32),
        _CtaStats(),
      ],
    );
  }
}

class _CtaText extends StatelessWidget {
  final bool centered;

  const _CtaText({this.centered = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.brandGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.brandGold.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.brandGold, size: 14),
              const SizedBox(width: 6),
              Text(
                'Penawaran Spesial — Diskon 50% Bulan Ini!',
                style: AppTextStyles.badge.copyWith(color: AppColors.brandGold),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.s24),

        Text(
          centered ? 'Mulai Perjalanan\nBisnis Anda Hari Ini' : 'Mulai Perjalanan\nBisnis Anda\nHari Ini',
          style: AppTextStyles.displayM.copyWith(color: Colors.white, height: 1.15),
          textAlign: centered ? TextAlign.center : TextAlign.left,
        ),

        const SizedBox(height: AppDimensions.s16),

        Text(
          'Bergabunglah dengan ribuan pengusaha sukses. Akses 50+ kursus premium dengan instruktur terbaik.',
          style: AppTextStyles.bodyL.copyWith(color: Colors.white.withValues(alpha: 0.75)),
          textAlign: centered ? TextAlign.center : TextAlign.left,
          maxLines: 3,
        ),

        const SizedBox(height: AppDimensions.s32),

        Wrap(
          spacing: AppDimensions.s16,
          runSpacing: AppDimensions.s12,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: [
            GradientButton(
              label: 'Daftar Sekarang',
              onTap: () => context.go(AppRouter.kursus),
              height: 56,
              horizontalPadding: 28,
              icon: Icons.rocket_launch_rounded,
              gradient: AppColors.goldGradient,
            ),
            _WhiteOutlineButton(
              label: 'Hubungi Kami',
              onTap: () => context.go(AppRouter.hubungi),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.s20),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.brandGreen, size: 16),
            const SizedBox(width: 6),
            Text(
              'Garansi uang kembali 30 hari jika tidak puas',
              style: AppTextStyles.bodyS.copyWith(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0);
  }
}

class _WhiteOutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _WhiteOutlineButton({required this.label, required this.onTap});

  @override
  State<_WhiteOutlineButton> createState() => _WhiteOutlineButtonState();
}

class _WhiteOutlineButtonState extends State<_WhiteOutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTextStyles.btnM.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CtaStatCard(icon: Icons.people_alt_rounded, value: '10.000+', label: 'Pelajar Bergabung'),
        const SizedBox(height: AppDimensions.s16),
        _CtaStatCard(icon: Icons.star_rounded, value: '4.9/5', label: 'Rating Rata-rata'),
        const SizedBox(height: AppDimensions.s16),
        _CtaStatCard(icon: Icons.workspace_premium_rounded, value: '98%', label: 'Pelajar Puas'),
      ],
    ).animate(delay: 300.ms).fadeIn(duration: 600.ms).slideX(begin: 0.2, end: 0);
  }
}

class _CtaStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CtaStatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppDimensions.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.h3OnDark),
              Text(label, style: AppTextStyles.bodyXS.copyWith(color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }
}

class _CtaPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width + size.height; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
