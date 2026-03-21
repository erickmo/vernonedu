import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../widgets/brand_navbar_widget.dart';
import '../widgets/menu_navbar_widget.dart';

class ShellPage extends StatelessWidget {
  final Widget child;
  const ShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/login'));
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final user = state.user;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Sticky dual navbar
              Material(
                elevation: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BrandNavbarWidget(
                        user: user,
                        onLogout: () => context.read<AuthCubit>().logout(),
                      ),
                      const MenuNavbarWidget(),
                    ],
                  ),
                ),
              ),
              // Content area — scrollable
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
