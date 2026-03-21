import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vernonedu_blockcoding/core/constants/app_colors.dart';
import 'package:vernonedu_blockcoding/core/constants/app_dimensions.dart';
import 'package:vernonedu_blockcoding/core/constants/app_strings.dart';
import 'package:vernonedu_blockcoding/core/di/injection.dart';

const String _kOnboardingDone = 'onboarding_done';

class _OnboardingData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<Color> gradient;

  const _OnboardingData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

/// Halaman onboarding — tampil saat pertama kali buka app.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingData(
      icon: Icons.widgets_rounded,
      iconColor: AppColors.blockControl,
      title: AppStrings.onboarding1Title,
      description: AppStrings.onboarding1Desc,
      gradient: [AppColors.surface, AppColors.surfaceVariant],
    ),
    _OnboardingData(
      icon: Icons.drag_indicator_rounded,
      iconColor: AppColors.blockIO,
      title: AppStrings.onboarding2Title,
      description: AppStrings.onboarding2Desc,
      gradient: [AppColors.surfaceVariant, AppColors.surface],
    ),
    _OnboardingData(
      icon: Icons.play_circle_fill_rounded,
      iconColor: AppColors.success,
      title: AppStrings.onboarding3Title,
      description: AppStrings.onboarding3Desc,
      gradient: [AppColors.surface, AppColors.surfaceVariant],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // — Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingSlide(data: _pages[i]),
          ),

          // — Skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text(
                  AppStrings.onboardingSkip,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ),

          // — Bottom navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final isLast = _currentPage == _pages.length - 1;

    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.spacingL,
        right: AppDimensions.spacingL,
        bottom: MediaQuery.of(context).padding.bottom + AppDimensions.spacingL,
        top: AppDimensions.spacingM,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // — Dots
          Row(
            children: List.generate(
              _pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
          ),

          // — Button
          GestureDetector(
            onTap: isLast ? _finish : _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: isLast ? AppDimensions.spacingL : AppDimensions.spacingM,
                vertical: AppDimensions.spacingM,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLast
                        ? AppStrings.onboardingStart
                        : AppStrings.onboardingNext,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingXs),
                  Icon(
                    isLast
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(_kOnboardingDone, true);
    if (mounted) context.go('/home');
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: data.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // — Illustration
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: data.iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.iconColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  data.icon,
                  color: data.iconColor,
                  size: 80,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXxl),

              // — Blocks illustration
              _buildBlocksIllustration(data.iconColor),
              const SizedBox(height: AppDimensions.spacingXl),

              // — Text
              Text(
                data.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                data.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              // Space for bottom nav
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlocksIllustration(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMiniBlock(AppColors.blockControl, 'Mulai'),
        const Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 14),
        _buildMiniBlock(AppColors.blockIO, 'Tampilkan'),
        const Icon(Icons.arrow_forward_rounded, color: AppColors.textHint, size: 14),
        _buildMiniBlock(AppColors.blockControl, 'Selesai'),
      ],
    );
  }

  Widget _buildMiniBlock(Color color, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
