import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/habit/presentation/pages/habit_page.dart';
import '../../features/quest/presentation/pages/quest_page.dart';
import '../../features/quest/presentation/pages/quest_detail_page.dart';
import '../../features/reward/presentation/pages/reward_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../di/injection.dart';

/// Route name constants.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String quests = '/quests';
  static const String questDetail = '/quests/:id';
  static const String habits = '/habits';
  static const String rewards = '/rewards';
  static const String profile = '/profile';
}

/// Router aplikasi menggunakan go_router.
class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: _guard,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => _ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.quests,
            builder: (context, state) => const QuestPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    QuestDetailPage(questId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.habits,
            builder: (context, state) => const HabitPage(),
          ),
          GoRoute(
            path: AppRoutes.rewards,
            builder: (context, state) => const RewardPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.error}'),
      ),
    ),
  );

  static Future<String?> _guard(
      BuildContext context, GoRouterState state) async {
    final prefs = getIt<SharedPreferences>();
    final token = prefs.getString(AppConstants.accessTokenKey);
    final onboardingDone =
        prefs.getBool(AppConstants.onboardingDoneKey) ?? false;

    final isOnSplash = state.uri.path == AppRoutes.splash;
    final isOnAuth = state.uri.path == AppRoutes.login ||
        state.uri.path == AppRoutes.onboarding;

    if (isOnSplash) {
      if (!onboardingDone) return AppRoutes.onboarding;
      if (token == null) return AppRoutes.login;
      return AppRoutes.dashboard;
    }

    if (token == null && !isOnAuth) return AppRoutes.login;
    if (token != null && isOnAuth) return AppRoutes.dashboard;
    return null;
  }
}

/// Splash page sementara untuk redirect guard.
class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Shell scaffold dengan bottom navigation bar.
class _ShellScaffold extends StatelessWidget {
  final Widget child;

  const _ShellScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    final navItems = [
      (icon: Icons.home_rounded, label: 'Beranda', path: AppRoutes.dashboard),
      (icon: Icons.task_alt_rounded, label: 'Misi', path: AppRoutes.quests),
      (
        icon: Icons.favorite_rounded,
        label: 'Kebiasaan',
        path: AppRoutes.habits
      ),
      (icon: Icons.card_giftcard_rounded, label: 'Hadiah', path: AppRoutes.rewards),
      (icon: Icons.person_rounded, label: 'Profil', path: AppRoutes.profile),
    ];

    int currentIndex = navItems.indexWhere((e) => location.startsWith(e.path));
    if (currentIndex == -1) currentIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(navItems[i].path),
        destinations: navItems
            .map(
              (e) => NavigationDestination(
                icon: Icon(e.icon),
                label: e.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
