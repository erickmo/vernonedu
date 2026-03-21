import 'package:go_router/go_router.dart';
import 'package:vernonedu_blockcoding/features/block_editor/presentation/pages/block_editor_page.dart';
import 'package:vernonedu_blockcoding/features/home/presentation/pages/home_page.dart';
import 'package:vernonedu_blockcoding/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vernonedu_blockcoding/features/splash/presentation/pages/splash_page.dart';

/// Konfigurasi routing seluruh aplikasi.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomePage(),
    ),
    GoRoute(
      path: '/editor',
      builder: (_, __) => const BlockEditorPage(),
    ),
    GoRoute(
      path: '/editor/:challengeId',
      builder: (_, state) => BlockEditorPage(
        challengeId: state.pathParameters['challengeId'],
      ),
    ),
  ],
);
