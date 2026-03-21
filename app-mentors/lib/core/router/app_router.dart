import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/injection.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/batch/domain/entities/batch_entity.dart';
import '../../features/batch/presentation/cubit/batch_list_cubit.dart';
import '../../features/batch/presentation/pages/batch_detail_page.dart';
import '../../features/batch/presentation/pages/batch_list_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/assignment/presentation/pages/assign_facilitator_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/shell/presentation/pages/shell_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _scheduleNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'schedule');
final _batchesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'batches');
final _profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

GoRouter createRouter(AuthCubit authCubit) => GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/home',
      redirect: (context, state) {
        final authState = authCubit.state;
        final isLoginRoute = state.matchedLocation == '/login';

        if (authState is AuthInitial) return null;

        if (authState is AuthUnauthenticated) {
          return isLoginRoute ? null : '/login';
        }

        if (authState is AuthAuthenticated && isLoginRoute) {
          return '/home';
        }

        return null;
      },
      refreshListenable: _AuthStateListenable(authCubit),
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => BlocProvider(
            create: (_) => getIt<BatchListCubit>()..loadBatches(),
            child: ShellPage(navigationShell: navigationShell),
          ),
          branches: [
            StatefulShellBranch(
              navigatorKey: _homeNavigatorKey,
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _scheduleNavigatorKey,
              routes: [
                GoRoute(
                  path: '/schedule',
                  builder: (context, state) => const SchedulePage(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _batchesNavigatorKey,
              routes: [
                GoRoute(
                  path: '/batches',
                  builder: (context, state) => const BatchListPage(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) => BatchDetailPage(
                        batchId: state.pathParameters['id']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'attendance',
                          builder: (context, state) => AttendancePage(
                            batchId: state.pathParameters['id']!,
                          ),
                        ),
                        GoRoute(
                          path: 'assign-facilitator',
                          builder: (context, state) {
                            final batch = state.extra as BatchEntity;
                            return AssignFacilitatorPage(
                              batchId: state.pathParameters['id']!,
                              batch: batch,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _profileNavigatorKey,
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
      ],
    );

class _AuthStateListenable extends ChangeNotifier {
  final AuthCubit _authCubit;

  _AuthStateListenable(this._authCubit) {
    _authCubit.stream.listen((_) => notifyListeners());
  }
}
