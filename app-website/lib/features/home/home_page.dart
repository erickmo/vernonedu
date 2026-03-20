import 'package:flutter/material.dart';

import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/navbar_widget.dart';
import 'widgets/courses_preview_section.dart';
import 'widgets/cta_section.dart';
import 'widgets/features_section.dart';
import 'widgets/hero_section.dart';
import 'widgets/how_it_works_section.dart';
import 'widgets/partners_section.dart';
import 'widgets/stats_section.dart';
import 'widgets/testimonials_section.dart';

/// Halaman utama VernonEdu Website.
/// Berisi: Hero, Stats, Features, Courses Preview, How It Works, Testimonials, Partners, CTA, Footer.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      body: const Column(
        children: [
          HeroSection(),
          StatsSection(),
          FeaturesSection(),
          CoursesPreviewSection(),
          HowItWorksSection(),
          TestimonialsSection(),
          PartnersSection(),
          CtaSection(),
          FooterWidget(),
        ],
      ),
    );
  }
}
