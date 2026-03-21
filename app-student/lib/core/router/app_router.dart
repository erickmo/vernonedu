import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/course/presentation/pages/course_page.dart';
import '../../features/certificate/presentation/pages/certificate_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../core/di/injection.dart';

class AppRouter {
  AppRouter._();

  static String _getInitialLocation() {
    final prefs = getIt<SharedPreferences>();
    final token = prefs.getString(AppConstants.accessTokenKey);
    return token != null ? '/home' : '/login';
  }

  static final router = GoRouter(
    initialLocation: _getInitialLocation(),
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AuthCubit>(),
          child: const LoginPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => getIt<AuthCubit>()..checkAuth(),
          child: ShellPage(child: child),
        ),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(path: '/schedule', builder: (context, state) => const SchedulePage()),
          GoRoute(path: '/course', builder: (context, state) => const CoursePage()),
          GoRoute(path: '/certificate', builder: (context, state) => const CertificatePage()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        ],
      ),
    ],
    redirect: (context, state) {
      final prefs = getIt<SharedPreferences>();
      final token = prefs.getString(AppConstants.accessTokenKey);
      final isOnLogin = state.matchedLocation == '/login';

      if (token == null && !isOnLogin) return '/login';
      if (token != null && isOnLogin) return '/home';
      return null;
    },
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan')),
    ),
  );
}
