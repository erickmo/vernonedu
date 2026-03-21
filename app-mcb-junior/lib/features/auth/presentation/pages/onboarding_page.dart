import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';

/// Data slide onboarding.
class _OnboardingSlide {
  final String emoji;
  final String title;
  final String description;
  final Color bgColor;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.description,
    required this.bgColor,
  });
}

/// Halaman onboarding pertama kali buka app.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      emoji: '🦸',
      title: AppStrings.onboardingTitle1,
      description: AppStrings.onboardingDesc1,
      bgColor: Color(0xFFEEF2FF),
    ),
    _OnboardingSlide(
      emoji: '⭐',
      title: AppStrings.onboardingTitle2,
      description: AppStrings.onboardingDesc2,
      bgColor: Color(0xFFFFFBEB),
    ),
    _OnboardingSlide(
      emoji: '🎁',
      title: AppStrings.onboardingTitle3,
      description: AppStrings.onboardingDesc3,
      bgColor: Color(0xFFF0FFF4),
    ),
  ];

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(AppConstants.onboardingDoneKey, true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    AppStrings.skip,
                    style: AppTextStyles.labelL.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _OnboardingSlideWidget(
                  slide: _slides[i],
                ),
              ),
            ),

            // Indicators
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingL,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingXS,
                    ),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusCircle),
                    ),
                  ),
                ),
              ),
            ),

            // Next / Start button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingXL,
                0,
                AppDimensions.spacingXL,
                AppDimensions.spacingXL,
              ),
              child: ElevatedButton(
                onPressed: _next,
                child: Text(
                  _currentPage == _slides.length - 1
                      ? AppStrings.letsStart
                      : AppStrings.next,
                  style: AppTextStyles.buttonL,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideWidget extends StatelessWidget {
  final _OnboardingSlide slide;

  const _OnboardingSlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: slide.bgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                slide.emoji,
                style: const TextStyle(fontSize: 96),
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spacingXXL),

          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayMedium,
          ),

          const SizedBox(height: AppDimensions.spacingM),

          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyL,
          ),
        ],
      ),
    );
  }
}
