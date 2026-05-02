import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vernonedu_dashboard/core/errors/failures.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/entities/finance_analysis_entity.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_batch_profit_analysis_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_cash_forecast_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_cost_analysis_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_finance_alerts_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_finance_suggestions_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_financial_ratios_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/domain/usecases/get_revenue_analysis_usecase.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/presentation/cubit/finance_analysis_cubit.dart';
import 'package:vernonedu_dashboard/features/finance_analysis/presentation/cubit/finance_analysis_state.dart';

class _MRatios extends Mock implements GetFinancialRatiosUseCase {}

class _MRevenue extends Mock implements GetRevenueAnalysisUseCase {}

class _MCosts extends Mock implements GetCostAnalysisUseCase {}

class _MBatch extends Mock implements GetBatchProfitAnalysisUseCase {}

class _MCash extends Mock implements GetCashForecastUseCase {}

class _MAlerts extends Mock implements GetFinanceAlertsUseCase {}

class _MSugg extends Mock implements GetFinanceSuggestionsUseCase {}

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
  late _MRatios mRatios;
  late _MRevenue mRevenue;
  late _MCosts mCosts;
  late _MBatch mBatch;
  late _MCash mCash;
  late _MAlerts mAlerts;
  late _MSugg mSugg;

  FinanceAnalysisCubit build() => FinanceAnalysisCubit(
        getRatios: mRatios,
        getRevenue: mRevenue,
        getCosts: mCosts,
        getBatchProfit: mBatch,
        getCashForecast: mCash,
        getAlerts: mAlerts,
        getSuggestions: mSugg,
      );

  setUp(() {
    mRatios = _MRatios();
    mRevenue = _MRevenue();
    mCosts = _MCosts();
    mBatch = _MBatch();
    mCash = _MCash();
    mAlerts = _MAlerts();
    mSugg = _MSugg();
  });

  void stubAllSuccess() {
    when(() => mRatios(
        period: any(named: 'period'),
        branchId: any(named: 'branchId'),
        comparison: any(named: 'comparison'))).thenAnswer(
        (_) async => const Right<Failure, FinancialRatiosEntity>(_ratios));
    when(() => mRevenue(
        period: any(named: 'period'),
        branchId: any(named: 'branchId'),
        groupBy: any(named: 'groupBy'))).thenAnswer(
        (_) async => const Right<Failure, RevenueAnalysisEntity>(_revenue));
    when(() => mCosts(
        period: any(named: 'period'),
        branchId: any(named: 'branchId'),
        groupBy: any(named: 'groupBy'))).thenAnswer(
        (_) async => const Right<Failure, CostAnalysisEntity>(_costs));
    when(() => mBatch(
        period: any(named: 'period'),
        branchId: any(named: 'branchId'),
        sort: any(named: 'sort'),
        limit: any(named: 'limit'))).thenAnswer(
        (_) async => const Right<Failure, BatchProfitEntity>(_batchProfit));
    when(() => mCash(
        months: any(named: 'months'),
        branchId: any(named: 'branchId'))).thenAnswer((_) async =>
        const Right<Failure, CashForecastEntity>(_cashForecast));
    when(() => mAlerts())
        .thenAnswer((_) async => const Right<Failure, List<FinancialAlert>>([]));
    when(() => mSugg()).thenAnswer(
        (_) async => const Right<Failure, List<FinancialSuggestion>>([]));
  }

  test('loadAll emits Loading then Loaded when all 7 calls succeed', () async {
    stubAllSuccess();
    final cubit = build();

    final states = <FinanceAnalysisState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states.first, isA<FinanceAnalysisLoading>());
    expect(states.last, isA<FinanceAnalysisLoaded>());
    final loaded = states.last as FinanceAnalysisLoaded;
    expect(loaded.ratios, _ratios);
    expect(loaded.revenue, _revenue);
    expect(loaded.costs, _costs);
    expect(loaded.batchProfit, _batchProfit);
    expect(loaded.cashForecast, _cashForecast);
    expect(loaded.alerts, isEmpty);
    expect(loaded.suggestions, isEmpty);
  });

  test('loadAll emits Error when any call fails', () async {
    stubAllSuccess();
    when(() => mRevenue(
        period: any(named: 'period'),
        branchId: any(named: 'branchId'),
        groupBy: any(named: 'groupBy'))).thenAnswer((_) async =>
        const Left<Failure, RevenueAnalysisEntity>(ServerFailure('boom')));
    final cubit = build();

    final states = <FinanceAnalysisState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(states.last, isA<FinanceAnalysisError>());
    expect((states.last as FinanceAnalysisError).message, contains('boom'));
  });
}
