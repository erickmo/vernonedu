import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/scroll_animate_widget.dart';
import '../../../core/widgets/section_header.dart';

/// Testimonial section — slider + 3 featured cards.
class TestimonialsSection extends StatefulWidget {
  const TestimonialsSection({super.key});

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  final PageController _controller = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  static const _testimonials = [
    _Testimonial(
      name: 'Andi Prasetyo',
      role: 'Founder, TechUMKM.id',
      quote:
          'VernonEdu benar-benar mengubah cara saya berpikir tentang bisnis. Dalam 3 bulan setelah mengikuti kursus "Bisnis dari Nol", omset toko saya naik 300%. Materi sangat praktis dan langsung bisa diterapkan!',
      avatar: 'AP',
      rating: 5,
      result: 'Omset naik 300%',
      color: Color(0xFF4F46E5),
      course: 'Membangun Bisnis dari Nol',
    ),
    _Testimonial(
      name: 'Siti Rahayu',
      role: 'CEO, Batik Nusantara Online',
      quote:
          'Kursus Digital Marketing di VernonEdu sangat komprehensif. Saya bisa membangun toko online yang menghasilkan Rp 50 juta per bulan hanya dalam 6 bulan. Instrukturnya sangat responsif dan membantu.',
      avatar: 'SR',
      rating: 5,
      result: 'Revenue Rp 50jt/bulan',
      color: Color(0xFF7C3AED),
      course: 'Digital Marketing untuk Pengusaha',
    ),
    _Testimonial(
      name: 'Budi Santoso',
      role: 'Co-Founder, FreshMart App',
      quote:
          'Komunitas VernonEdu luar biasa! Saya tidak hanya dapat ilmu, tapi juga mendapat partner bisnis dari sini. Sekarang startup saya sudah dapat pendanaan pre-seed berkat networking yang saya bangun.',
      avatar: 'BS',
      rating: 5,
      result: 'Dapat pendanaan pre-seed',
      color: Color(0xFF10B981),
      course: 'Business Model Canvas & Startup',
    ),
    _Testimonial(
      name: 'Dewi Lestari',
      role: 'Owner, Kue Artisan By Dewi',
      quote:
          'Awalnya ragu, tapi ternyata kursus Manajemen Keuangan Bisnis sangat worth it. Sekarang saya bisa kelola keuangan bisnis dengan benar dan profit margin naik 45%. Best investment ever!',
      avatar: 'DL',
      rating: 5,
      result: 'Profit margin +45%',
      color: Color(0xFFF59E0B),
      course: 'Manajemen Keuangan Bisnis',
    ),
    _Testimonial(
      name: 'Rizky Fauzan',
      role: 'Direktur, CV Maju Bersama',
      quote:
          'Leadership training di VernonEdu membuka perspektif saya. Tim saya kini lebih produktif dan harmonis. Turnover karyawan turun drastis dan revenue company tumbuh 180% dalam setahun.',
      avatar: 'RF',
      rating: 5,
      result: 'Revenue tumbuh 180%',
      color: Color(0xFF3B82F6),
      course: 'Leadership & Tim Management',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padH = Responsive.sectionPaddingH(context);
    final padV = Responsive.sectionPaddingV(context);

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
                    'Bergabunglah dengan ribuan pengusaha yang telah mengubah bisnis mereka bersama VernonEdu.',
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.s48),

          // Testimonial slider
          SizedBox(
            height: isMobile ? 380 : 320,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (p) => setState(() => _currentPage = p),
              itemCount: _testimonials.length,
              itemBuilder: (context, i) {
                return AnimatedScale(
                  scale: _currentPage == i ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _TestimonialCard(
                      testimonial: _testimonials[i],
                      index: i,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppDimensions.s32),

          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Prev
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

              // Dots
              Row(
                children: List.generate(
                  _testimonials.length,
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

              // Next
              _NavButton(
                icon: Icons.arrow_forward_rounded,
                onTap: _currentPage < _testimonials.length - 1
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
  final _Testimonial testimonial;
  final int index;

  const _TestimonialCard({required this.testimonial, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.s24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.r20),
        border: Border.all(
          color: testimonial.color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: testimonial.color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars + result badge
          Row(
            children: [
              Row(
                children: List.generate(
                  testimonial.rating,
                  (_) => const Icon(Icons.star_rounded,
                      color: AppColors.brandGold, size: 16),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: testimonial.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: testimonial.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded,
                        color: testimonial.color, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      testimonial.result,
                      style: AppTextStyles.bodyXS.copyWith(
                        color: testimonial.color,
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

          // Quote icon
          Icon(Icons.format_quote_rounded,
              color: testimonial.color.withValues(alpha: 0.4), size: 28),

          const SizedBox(height: AppDimensions.s8),

          // Quote text
          Expanded(
            child: Text(
              testimonial.quote,
              style: AppTextStyles.bodyM.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: AppDimensions.s16),

          // Divider
          Container(height: 1, color: AppColors.border),

          const SizedBox(height: AppDimensions.s16),

          // Author
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [testimonial.color, testimonial.color.withValues(alpha: 0.5)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    testimonial.avatar,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppDimensions.s12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(testimonial.name, style: AppTextStyles.labelM),
                    Text(
                      testimonial.role,
                      style: AppTextStyles.bodyXS,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Course badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  testimonial.course,
                  style: AppTextStyles.bodyXS.copyWith(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: (index * 100).ms)
        .fadeIn(duration: 500.ms);
  }
}

class _Testimonial {
  final String name;
  final String role;
  final String quote;
  final String avatar;
  final int rating;
  final String result;
  final Color color;
  final String course;

  const _Testimonial({
    required this.name,
    required this.role,
    required this.quote,
    required this.avatar,
    required this.rating,
    required this.result,
    required this.color,
    required this.course,
  });
}
