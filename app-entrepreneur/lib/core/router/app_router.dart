import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/administration/presentation/pages/administration_page.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/business_ideation/presentation/cubit/business_cubit.dart';
import '../../features/business_ideation/presentation/cubit/canvas_item_cubit.dart';
import '../../features/business_ideation/presentation/pages/business_detail_page.dart';
import '../../features/business_ideation/presentation/pages/business_ideation_page.dart';
import '../../features/business_ideation/presentation/pages/worksheet_page.dart';
import '../../features/course/presentation/pages/course_page.dart';
import '../../features/students/presentation/pages/students_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/block_coding/presentation/pages/block_coding_home_page.dart';
import '../../features/block_coding/presentation/pages/block_editor_page.dart';
import '../../features/dashboard/presentation/pages/shell_page.dart';
import '../../features/launchpad/presentation/pages/launchpad_detail_page.dart';
import '../../features/launchpad/presentation/pages/launchpad_page.dart';
import '../../features/launchpad/presentation/pages/launchpad_step_page.dart';
import '../../features/learning/presentation/pages/learning_page.dart';
import '../../features/hr/presentation/pages/hr_page.dart';
import '../../features/marketing/presentation/pages/marketing_page.dart';
import '../../features/operations/presentation/pages/operations_page.dart';
import '../constants/app_constants.dart';
import '../di/injection.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final prefs = getIt<SharedPreferences>();
      final token = prefs.getString(AppConstants.accessTokenKey);
      final isLoggedIn = token != null && token.isNotEmpty;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<AuthCubit>(),
          child: const LoginPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellPage(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/learning',
            builder: (context, state) => const LearningPage(),
          ),
          GoRoute(
            path: '/business-ideation',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<BusinessCubit>()..getBusinesses(),
              child: const BusinessIdeationPage(),
            ),
            routes: [
              GoRoute(
                path: ':businessId',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<BusinessCubit>(),
                  child: BusinessDetailPage(
                    businessId: state.pathParameters['businessId']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'worksheet/:worksheetKey',
                    builder: (context, state) => BlocProvider(
                      create: (_) => getIt<CanvasItemCubit>(),
                      child: WorksheetPage(
                        businessId: state.pathParameters['businessId']!,
                        worksheetKey: state.pathParameters['worksheetKey']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/launchpad',
            builder: (context, state) => const LaunchpadPage(),
            routes: [
              GoRoute(
                path: ':businessId',
                builder: (context, state) => LaunchpadDetailPage(
                  businessId: state.pathParameters['businessId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'step/:stepKey',
                    builder: (context, state) => LaunchpadStepPage(
                      businessId: state.pathParameters['businessId']!,
                      stepKey: state.pathParameters['stepKey']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/operations',
            builder: (context, state) => const OperationsPage(),
          ),
          GoRoute(
            path: '/administration',
            builder: (context, state) => const AdministrationPage(),
          ),
          GoRoute(
            path: '/marketing',
            builder: (context, state) => const MarketingPage(),
          ),
          GoRoute(
            path: '/hr',
            builder: (context, state) => const HrPage(),
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) =>
                const _PlaceholderContent(title: 'Finance & Reporting'),
          ),
          GoRoute(
            path: '/course',
            builder: (context, state) => const CoursePage(),
          ),
          GoRoute(
            path: '/students',
            builder: (context, state) => const StudentsPage(),
          ),
          GoRoute(
            path: '/block-coding',
            builder: (context, state) => const BlockCodingHomePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/block-coding/editor',
        builder: (context, state) => const BlockEditorPage(),
      ),
      GoRoute(
        path: '/block-coding/editor/:challengeId',
        builder: (context, state) => BlockEditorPage(
          challengeId: state.pathParameters['challengeId'],
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.error}'),
      ),
    ),
  );
}

class _PlaceholderContent extends StatelessWidget {
  final String title;

  const _PlaceholderContent({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
