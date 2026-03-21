import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/navbar_widget.dart';
import 'cubit/home_cubit.dart';
import 'widgets/audience_selector_section.dart';
import 'widgets/cta_section.dart';
import 'widgets/hero_section.dart';
import 'widgets/how_it_works_section.dart';
import 'widgets/program_highlights_section.dart';
import 'widgets/social_proof_bar_section.dart';
import 'widgets/stats_section.dart';
import 'widgets/testimonials_section.dart';
import 'widgets/courses_preview_section.dart';

/// Halaman utama VernonEdu Website.
/// 9 section:
///   1. Hero          — CTA "Lihat Program" + "Daftar Sekarang"
///   2. SocialProofBar — stats live dari /public/stats
///   3. ProgramHighlights — 4 kartu program
///   4. AudienceSelector  — "Untuk Siapa?" tabs
///   5. CoursesPreview    — 6 kursus dari /public/courses
///   6. HowItWorks        — 3 langkah static + scroll animation
///   7. Testimonials      — carousel dari /public/testimonials
///   8. StatsCounter      — animated counters dari /public/stats
///   9. CTA Banner        — "Siap Memulai?" + Footer
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit()..loadAll(),
      child: WebScaffold(
        body: const Column(
          children: [
            // Section 1: Hero
            HeroSection(),

            // Section 2: Social Proof Bar (live stats)
            SocialProofBarSection(),

            // Section 3: Program Highlights
            ProgramHighlightsSection(),

            // Section 4: Audience Selector
            AudienceSelectorSection(),

            // Section 5: Featured Courses (from API)
            CoursesPreviewSection(),

            // Section 6: How It Works (3 steps)
            HowItWorksSection(),

            // Section 7: Testimonials Carousel (from API)
            TestimonialsSection(),

            // Section 8: Stats Counter (animated, from API)
            StatsSection(),

            // Section 9: CTA Banner
            CtaSection(),

            FooterWidget(),
          ],
        ),
      ),
    );
  }
}
