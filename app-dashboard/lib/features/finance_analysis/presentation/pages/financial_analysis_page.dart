import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/finance_analysis_cubit.dart';
import '../cubit/finance_analysis_state.dart';
import '../widgets/analysis_alerts_card.dart';
import '../widgets/analysis_batch_profit_card.dart';
import '../widgets/analysis_cash_forecast_card.dart';
import '../widgets/analysis_cost_card.dart';
import '../widgets/analysis_ratio_card.dart';
import '../widgets/analysis_revenue_card.dart';
import '../widgets/analysis_suggestions_card.dart';

/// Roles allowed to access financial analysis dashboard.
const Set<UserRole> _kAllowedRoles = {
  UserRole.director,
  UserRole.accountingLeader,
  UserRole.accountingStaff,
};

/// Desktop breakpoint — 2 columns at >=900, 1 column otherwise.
const double _kDesktopBreakpoint = 900;

class FinancialAnalysisPage extends StatelessWidget {
  const FinancialAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analisis Keuangan'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }
          final hasAccess =
              authState.user.roles.any(_kAllowedRoles.contains);
          if (!hasAccess) return const _ForbiddenView();
          return BlocProvider(
            create: (_) => getIt<FinanceAnalysisCubit>()..loadAll(),
            child: const _AnalysisView(),
          );
        },
      ),
    );
  }
}

class _ForbiddenView extends StatelessWidget {
  const _ForbiddenView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: AppColors.textSecondary),
            SizedBox(height: AppDimensions.md),
            Text(
              'Akses ditolak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppDimensions.xs),
            Text(
              'Halaman ini hanya untuk Direktur, Accounting Leader, atau Accounting Staff.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisView extends StatelessWidget {
  const _AnalysisView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceAnalysisCubit, FinanceAnalysisState>(
      builder: (context, state) {
        if (state is FinanceAnalysisLoading || state is FinanceAnalysisInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is FinanceAnalysisError) {
          return _ErrorView(message: state.message);
        }
        return _LoadedContent(state: state as FinanceAnalysisLoaded);
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: AppDimensions.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.md),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<FinanceAnalysisCubit>().loadAll(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedContent extends StatelessWidget {
  final FinanceAnalysisLoaded state;
  const _LoadedContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnalysisRatioCard(ratios: state.ratios),
              const SizedBox(height: AppDimensions.md),
              if (isDesktop)
                _Row2(
                  left: AnalysisRevenueCard(revenue: state.revenue),
                  right: AnalysisCostCard(costs: state.costs),
                )
              else ...[
                AnalysisRevenueCard(revenue: state.revenue),
                const SizedBox(height: AppDimensions.md),
                AnalysisCostCard(costs: state.costs),
              ],
              const SizedBox(height: AppDimensions.md),
              AnalysisBatchProfitCard(batchProfit: state.batchProfit),
              const SizedBox(height: AppDimensions.md),
              AnalysisCashForecastCard(cashForecast: state.cashForecast),
              const SizedBox(height: AppDimensions.md),
              AnalysisAlertsCard(alerts: state.alerts),
              const SizedBox(height: AppDimensions.md),
              AnalysisSuggestionsCard(suggestions: state.suggestions),
            ],
          );
        },
      ),
    );
  }
}

class _Row2 extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _Row2({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppDimensions.md),
        Expanded(child: right),
      ],
    );
  }
}
