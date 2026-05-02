import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/entities/finance_analysis_entity.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/repositories/finance_analysis_repository.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_batch_profit_analysis_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_cash_forecast_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_cost_analysis_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_finance_alerts_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_finance_suggestions_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_financial_ratios_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_revenue_analysis_usecase.dart';

class _MockRepo extends Mock implements FinanceAnalysisRepository {}

const _ratios = FinancialRatiosEntity(
  profitMargin: RatioMetric.empty,
  expenseRatio: RatioMetric.empty,
  revenuePerStudent: RatioMetric.empty,
  costPerStudent: RatioMetric.empty,
  avgBatchProfitability: RatioMetric.empty,
  collectionRate: RatioMetric.empty,
  daysSalesOutstanding: RatioMetric.empty,
  revenueGrowthRate: RatioMetric.empty,
);

const _revenue = RevenueAnalysisEntity(
  monthlyTrend: [],
  byGroup: [],
  totalRevenue: 0,
  groupBy: 'month',
);

const _costs = CostAnalysisEntity(monthlyTrend: [], byCategory: [], totalCost: 0);

const _batchProfit = BatchProfitEntity(items: [], avgMargin: 0, sort: 'top');

const _cashForecast = CashForecastEntity(
  currentCash: 0,
  months: [],
  upcomingEvents: [],
);

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  test('GetFinancialRatiosUseCase delegates to repository', () async {
    when(() => repo.getRatios(
          period: any(named: 'period'),
          branchId: any(named: 'branchId'),
          comparison: any(named: 'comparison'),
        )).thenAnswer((_) async => const Right<Failure, FinancialRatiosEntity>(_ratios));

    final r = await GetFinancialRatiosUseCase(repo)();
    expect(r.isRight(), true);
  });

  test('GetRevenueAnalysisUseCase delegates to repository', () async {
    when(() => repo.getRevenue(
          period: any(named: 'period'),
          branchId: any(named: 'branchId'),
          groupBy: any(named: 'groupBy'),
        )).thenAnswer((_) async => const Right<Failure, RevenueAnalysisEntity>(_revenue));
    final r = await GetRevenueAnalysisUseCase(repo)();
    expect(r.isRight(), true);
  });

  test('GetCostAnalysisUseCase delegates to repository', () async {
    when(() => repo.getCosts(
          period: any(named: 'period'),
          branchId: any(named: 'branchId'),
          groupBy: any(named: 'groupBy'),
        )).thenAnswer((_) async => const Right<Failure, CostAnalysisEntity>(_costs));
    final r = await GetCostAnalysisUseCase(repo)();
    expect(r.isRight(), true);
  });

  test('GetBatchProfitAnalysisUseCase delegates to repository', () async {
    when(() => repo.getBatchProfit(
          period: any(named: 'period'),
          branchId: any(named: 'branchId'),
          sort: any(named: 'sort'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => const Right<Failure, BatchProfitEntity>(_batchProfit));
    final r = await GetBatchProfitAnalysisUseCase(repo)();
    expect(r.isRight(), true);
  });

  test('GetCashForecastUseCase delegates to repository', () async {
    when(() => repo.getCashForecast(
          months: any(named: 'months'),
          branchId: any(named: 'branchId'),
        )).thenAnswer((_) async => const Right<Failure, CashForecastEntity>(_cashForecast));
    final r = await GetCashForecastUseCase(repo)();
    expect(r.isRight(), true);
  });

  test('GetFinanceAlertsUseCase delegates to repository', () async {
    when(() => repo.getAlerts())
        .thenAnswer((_) async => const Right<Failure, List<FinancialAlert>>([]));
    final r = await GetFinanceAlertsUseCase(repo)();
    expect(r.isRight(), true);
  });

  test('GetFinanceSuggestionsUseCase delegates to repository', () async {
    when(() => repo.getSuggestions()).thenAnswer(
        (_) async => const Right<Failure, List<FinancialSuggestion>>([]));
    final r = await GetFinanceSuggestionsUseCase(repo)();
    expect(r.isRight(), true);
  });
}
