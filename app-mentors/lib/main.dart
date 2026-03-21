import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MentorsApp());
}

class MentorsApp extends StatefulWidget {
  const MentorsApp({super.key});

  @override
  State<MentorsApp> createState() => _MentorsAppState();
}

class _MentorsAppState extends State<MentorsApp> {
  late final AuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    _authCubit = getIt<AuthCubit>()..checkAuth();
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: _AppRouter(authCubit: _authCubit),
    );
  }
}

class _AppRouter extends StatefulWidget {
  final AuthCubit authCubit;

  const _AppRouter({required this.authCubit});

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late final router = createRouter(widget.authCubit);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VernonEdu Mentors',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
