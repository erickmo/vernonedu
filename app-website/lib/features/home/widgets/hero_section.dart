import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/gradient_button.dart';

/// Hero section — full viewport, light lavender gradient + floating shapes.
class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnim = CurvedAnimation(parent: _floatController, curve: Curves.easeInOut);
    _pulseAnim = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * (isMobile ? 0.95 : 1.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF8F7FF),
            Color(0xFFEDE9F8),
            Color(0xFFF8F7FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Floating soft orbs
          _FloatingOrbs(floatAnim: _floatAnim, pulseAnim: _pulseAnim),

          // Dot pattern
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

          // Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? AppDimensions.s24
                      : AppDimensions.sectionPaddingH,
                ),
                child: isMobile ? _MobileHeroContent() : _DesktopHeroContent(),
              ),
            ),
          ),

          // Bottom fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFFF8F7FF)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft floating orbs — melayang lembut dengan warna brand.
class _FloatingOrbs extends StatelessWidget {
  final Animation<double> floatAnim;
  final Animation<double> pulseAnim;

  const _FloatingOrbs({required this.floatAnim, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatAnim,
      builder: (context, _) {
        return Stack(
          children: [
            // Orb 1 — Purple besar kiri atas
            Positioned(
              left: -120,
              top: -100 + floatAnim.value * 30,
              child: _SoftOrb(size: 400, color: AppColors.brandPurple.withValues(alpha: 0.08)),
            ),
            // Orb 2 — Blue kanan atas
            Positioned(
              right: -80,
              top: 60 - floatAnim.value * 20,
              child: _SoftOrb(size: 320, color: AppColors.brandBlue.withValues(alpha: 0.07)),
            ),
            // Orb 3 — Green kecil tengah
            Positioned(
              left: MediaQuery.of(context).size.width * 0.35,
              bottom: 120 + floatAnim.value * 20,
              child: _SoftOrb(size: 200, color: AppColors.brandGreen.withValues(alpha: 0.06)),
            ),
            // Orb 4 — Orange kecil kanan bawah
            Positioned(
              right: 80,
              bottom: 200 - floatAnim.value * 15,
              child: _SoftOrb(size: 160, color: AppColors.brandOrange.withValues(alpha: 0.06)),
            ),
          ],
        );
      },
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

/// Dot pattern overlay — subtle texture.
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.brandPurple.withValues(alpha: 0.06)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const spacing = 32.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DesktopHeroContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: _HeroText()),
        const SizedBox(width: AppDimensions.s64),
        Expanded(flex: 4, child: _HeroVisual()),
      ],
    );
  }
}

class _MobileHeroContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HeroText(),
        const SizedBox(height: AppDimensions.s48),
        _HeroVisual(),
      ],
    );
  }
}

class _HeroText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge
        _HeroBadge()
            .animate()
            .fadeIn(duration: 600.ms)
            .slideX(begin: -0.3, end: 0),

        const SizedBox(height: AppDimensions.s24),

        // Headline
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Wujudkan\n',
                style: (isMobile ? AppTextStyles.displayM : AppTextStyles.displayL)
                    .copyWith(height: 1.1),
              ),
              TextSpan(
                text: 'Impian Bisnis',
                style: (isMobile ? AppTextStyles.displayM : AppTextStyles.displayL)
                    .copyWith(
                  height: 1.1,
                  foreground: Paint()
                    ..shader = AppColors.primaryGradient.createShader(
                      Rect.fromLTWH(0, 0, isMobile ? 300 : 480, 80),
                    ),
                ),
              ),
              TextSpan(
                text: '\nAnda Sekarang',
                style: (isMobile ? AppTextStyles.displayM : AppTextStyles.displayL)
                    .copyWith(height: 1.1),
              ),
            ],
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 700.ms)
            .slideY(begin: 0.3, end: 0),

        const SizedBox(height: AppDimensions.s24),

        Text(
          'Bergabung dengan 10.000+ pengusaha yang telah berhasil mengembangkan bisnis bersama VernonEdu. Kursus terstruktur, instruktur berpengalaman, dan komunitas yang supportif.',
          style: AppTextStyles.bodyL,
          maxLines: 4,
        )
            .animate(delay: 400.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.2, end: 0),

        const SizedBox(height: AppDimensions.s40),

        Wrap(
          spacing: AppDimensions.s16,
          runSpacing: AppDimensions.s16,
          children: [
            GradientButton(
              label: 'Mulai Belajar Gratis',
              onTap: () => context.go(AppRouter.kursus),
              height: 56,
              horizontalPadding: 32,
              icon: Icons.school_rounded,
            ),
            OutlineButton(
              label: 'Lihat Semua Kursus',
              onTap: () => context.go(AppRouter.kursus),
              height: 56,
              horizontalPadding: 28,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        )
            .animate(delay: 600.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.2, end: 0),

        const SizedBox(height: AppDimensions.s40),

        _SocialProof()
            .animate(delay: 800.ms)
            .fadeIn(duration: 500.ms),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandGold.withValues(alpha: 0.12),
            AppColors.brandPurple.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandGold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.brandGold, size: 16),
          const SizedBox(width: 8),
          Text(
            'Platform #1 Edukasi Wirausaha Indonesia',
            style: AppTextStyles.labelS.copyWith(color: AppColors.brandGold),
          ),
        ],
      ),
    );
  }
}

class _SocialProof extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 36,
          child: Stack(
            children: List.generate(4, (i) {
              final colors = [
                AppColors.brandPurple,
                AppColors.brandBlue,
                AppColors.brandGreen,
                AppColors.brandOrange,
              ];
              return Positioned(
                left: i * 22.0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[i],
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      ['AB', 'CD', 'EF', 'GH'][i],
                      style: AppTextStyles.bodyXS.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: AppDimensions.s16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (_) => const Icon(Icons.star_rounded, color: AppColors.brandGold, size: 14),
              ),
            ),
            const SizedBox(height: 2),
            Text('4.9/5 dari 2.847 ulasan', style: AppTextStyles.bodyXS),
          ],
        ),
      ],
    );
  }
}

/// Visual kanan — dashboard card floating.
class _HeroVisual extends StatefulWidget {
  @override
  State<_HeroVisual> createState() => _HeroVisualState();
}

class _HeroVisualState extends State<_HeroVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _float = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, -8 + _float.value * 16),
        child: _DashboardMockCard(),
      ),
    ).animate(delay: 500.ms).fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _DashboardMockCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.12),
            blurRadius: 48,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 0,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard Belajar', style: AppTextStyles.labelM),
                  Text('Bisnis dari Nol', style: AppTextStyles.bodyXS),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s20),
          Text('Progress Kursus', style: AppTextStyles.bodyXS),
          const SizedBox(height: 8),
          _ProgressBar(value: 0.68, label: '68%'),
          const SizedBox(height: AppDimensions.s20),
          Row(
            children: [
              _MiniStat(label: 'Modul', value: '12/18'),
              const SizedBox(width: AppDimensions.s16),
              _MiniStat(label: 'Jam Belajar', value: '24h'),
              const SizedBox(width: AppDimensions.s16),
              _MiniStat(label: 'Sertifikat', value: '2'),
            ],
          ),
          const SizedBox(height: AppDimensions.s16),
          Row(
            children: [
              _AchievementBadge(icon: Icons.military_tech_rounded, label: 'Top Student'),
              const SizedBox(width: 8),
              _AchievementBadge(
                icon: Icons.local_fire_department_rounded,
                label: '7 Day Streak',
                color: AppColors.brandGold,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.play_circle_filled_rounded,
                    color: AppColors.brandPurple, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Modul 13: Strategi Pricing',
                          style: AppTextStyles.labelS),
                      Text('Lanjut Belajar · 45 menit', style: AppTextStyles.bodyXS),
                    ],
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

class _ProgressBar extends StatelessWidget {
  final double value;
  final String label;

  const _ProgressBar({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress', style: AppTextStyles.bodyXS),
            Text(label, style: AppTextStyles.labelS.copyWith(color: AppColors.brandPurple)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.bgSurface,
            valueColor: const AlwaysStoppedAnimation(AppColors.brandPurple),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.labelM.copyWith(color: AppColors.brandPurple)),
        Text(label, style: AppTextStyles.bodyXS),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AchievementBadge({
    required this.icon,
    required this.label,
    this.color = AppColors.brandPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.bodyXS.copyWith(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
