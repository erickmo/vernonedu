import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/scroll_animate_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// Section 7: Testimonials Carousel — dari API /public/testimonials, fallback ke static.
class TestimonialsSection extends StatefulWidget {
  const TestimonialsSection({super.key});

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  final PageController _controller =
      PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  static const _fallbackTestimonials = [
    _StaticTestimonial(
      name: 'Andi Prasetyo',
      role: 'Founder, TechUMKM.id',
      quote:
          'VernonEdu benar-benar mengubah cara saya berpikir tentang bisnis. Dalam 3 bulan setelah mengikuti program, omset toko saya naik 300%.',
      initials: 'AP',
      rating: 5,
      result: 'Omset naik 300%',
      color: Color(0xFF4F46E5),
      course: 'Program Karir Digital',
    ),
    _StaticTestimonial(
      name: 'Siti Rahayu',
      role: 'CEO, Batik Nusantara Online',
      quote:
          'Kursus Digital Marketing di VernonEdu sangat komprehensif. Saya bisa membangun toko online yang menghasilkan Rp 50 juta per bulan.',
      initials: 'SR',
      rating: 5,
      result: 'Revenue Rp 50jt/bulan',
      color: Color(0xFF7C3AED),
      course: 'Digital Marketing',
    ),
    _StaticTestimonial(
      name: 'Budi Santoso',
      role: 'Co-Founder, FreshMart App',
      quote:
          'Komunitas VernonEdu luar biasa! Saya tidak hanya dapat ilmu, tapi juga mendapat partner bisnis dari sini. Startup saya dapat pendanaan pre-seed.',
      initials: 'BS',
      rating: 5,
      result: 'Dapat pendanaan pre-seed',
      color: Color(0xFF10B981),
      course: 'Business Canvas & Startup',
    ),
    _StaticTestimonial(
      name: 'Dewi Lestari',
      role: 'Owner, Kue Artisan By Dewi',
      quote:
          'Kursus Manajemen Keuangan Bisnis sangat worth it. Sekarang saya bisa kelola keuangan bisnis dengan benar dan profit margin naik 45%.',
      initials: 'DL',
      rating: 5,
      result: 'Profit margin +45%',
      color: Color(0xFFF59E0B),
      course: 'Manajemen Keuangan Bisnis',
    ),
    _StaticTestimonial(
      name: 'Rizky Fauzan',
      role: 'Direktur, CV Maju Bersama',
      quote:
          'Leadership training di VernonEdu membuka perspektif saya. Tim saya kini lebih produktif dan revenue company tumbuh 180% dalam setahun.',
      initials: 'RF',
      rating: 5,
      result: 'Revenue tumbuh 180%',
      color: Color(0xFF3B82F6),
      course: 'Leadership & Tim Management',
    ),
  ];

  static const _accentColors = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final isMobile = Responsive.isMobile(context);
        final padH = Responsive.sectionPaddingH(context);
        final padV = Responsive.sectionPaddingV(context);

        // Build unified display list
        final List<_DisplayTestimonial> displayList;
        if (state is HomeLoaded && state.testimonials.isNotEmpty) {
          displayList = state.testimonials.asMap().entries.map((e) {
            final t = e.value;
            return _DisplayTestimonial(
              name: t.studentName,
              role: '',
              quote: t.quote,
              initials: t.initials,
              rating: t.rating,
              result: '',
              color: _accentColors[e.key % _accentColors.length],
              course: '',
            );
          }).toList();
        } else {
          displayList = _fallbackTestimonials
              .map((t) => _DisplayTestimonial(
                    name: t.name,
                    role: t.role,
                    quote: t.quote,
                    initials: t.initials,
                    rating: t.rating,
                    result: t.result,
                    color: t.color,
                    course: t.course,
                  ))
              .toList();
        }

        // Clamp current page
        if (_currentPage >= displayList.length) {
          _currentPage = 0;
        }

        return Container(
          color: AppColors.bgSecondary.withValues(alpha: 0.3),
          padding: EdgeInsets.symmetric(vertical: padV),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padH),
                child: ScrollAnimateWidget(
                  uniqueKey: 'testimonials_header',
                  child: const SectionHeader(
                    badge: '💬 Kata Mereka',
                    title: 'Kisah Sukses\nPelajar VernonEdu',
                    subtitle:
                        'Bergabunglah dengan ribuan pelajar yang telah mengubah karir mereka bersama VernonEdu.',
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.s48),

              SizedBox(
                height: isMobile ? 380 : 300,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  itemCount: displayList.length,
                  itemBuilder: (context, i) {
                    return AnimatedScale(
                      scale: _currentPage == i ? 1.0 : 0.95,
                      duration: const Duration(milliseconds: 300),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: _TestimonialCard(
                          t: displayList[i],
                          index: i,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppDimensions.s32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: _currentPage > 0
                        ? () => _controller.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            )
                        : null,
                  ),

                  const SizedBox(width: AppDimensions.s16),

                  Row(
                    children: List.generate(
                      displayList.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == i ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: _currentPage == i
                              ? AppColors.primaryGradient
                              : null,
                          color: _currentPage == i
                              ? null
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDimensions.s16),

                  _NavButton(
                    icon: Icons.arrow_forward_rounded,
                    onTap: _currentPage < displayList.length - 1
                        ? () => _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final _DisplayTestimonial t;
  final int index;

  const _TestimonialCard({required this.t, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.r20),
        border: Border.all(
          color: t.color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: t.color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars + result
          Row(
            children: [
              Row(
                children: List.generate(
                  t.rating,
                  (_) => const Icon(Icons.star_rounded,
                      color: AppColors.brandGold, size: 16),
                ),
              ),
              const Spacer(),
              if (t.result.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: t.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded,
                          color: t.color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        t.result,
                        style: AppTextStyles.bodyXS.copyWith(
                          color: t.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppDimensions.s16),

          Icon(Icons.format_quote_rounded,
              color: t.color.withValues(alpha: 0.4), size: 28),

          const SizedBox(height: AppDimensions.s8),

          Expanded(
            child: Text(
              t.quote,
              style: AppTextStyles.bodyM.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: AppDimensions.s16),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimensions.s16),

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [t.color, t.color.withValues(alpha: 0.5)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    t.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppDimensions.s12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: AppTextStyles.labelM),
                    if (t.role.isNotEmpty)
                      Text(
                        t.role,
                        style: AppTextStyles.bodyXS,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              if (t.course.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    t.course,
                    style: AppTextStyles.bodyXS.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn(duration: 500.ms);
  }
}

// ─── Data models ───────────────────────────────────────────────────────────────

class _DisplayTestimonial {
  final String name;
  final String role;
  final String quote;
  final String initials;
  final int rating;
  final String result;
  final Color color;
  final String course;

  const _DisplayTestimonial({
    required this.name,
    required this.role,
    required this.quote,
    required this.initials,
    required this.rating,
    required this.result,
    required this.color,
    required this.course,
  });
}

class _StaticTestimonial {
  final String name;
  final String role;
  final String quote;
  final String initials;
  final int rating;
  final String result;
  final Color color;
  final String course;

  const _StaticTestimonial({
    required this.name,
    required this.role,
    required this.quote,
    required this.initials,
    required this.rating,
    required this.result,
    required this.color,
    required this.course,
  });
}
