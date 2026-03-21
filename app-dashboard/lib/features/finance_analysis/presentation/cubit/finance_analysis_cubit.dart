import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_financial_ratios_usecase.dart';
import '../../domain/usecases/get_revenue_analysis_usecase.dart';
import '../../domain/usecases/get_cost_analysis_usecase.dart';
import '../../domain/usecases/get_batch_profit_analysis_usecase.dart';
import '../../domain/usecases/get_cash_forecast_usecase.dart';
import '../../domain/usecases/get_finance_alerts_usecase.dart';
import '../../domain/usecases/get_finance_suggestions_usecase.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import 'finance_analysis_state.dart';

class FinanceAnalysisCubit extends Cubit<FinanceAnalysisState> {
  final GetFinancialRatiosUseCase getRatios;
  final GetRevenueAnalysisUseCase getRevenue;
  final GetCostAnalysisUseCase getCosts;
  final GetBatchProfitAnalysisUseCase getBatchProfit;
  final GetCashForecastUseCase getCashForecast;
  final GetFinanceAlertsUseCase getAlerts;
  final GetFinanceSuggestionsUseCase getSuggestions;

  String _period = 'monthly';
  String? _branchId;
  String _comparison = 'vs_last_month';

  FinanceAnalysisCubit({
    required this.getRatios,
    required this.getRevenue,
    required this.getCosts,
    required this.getBatchProfit,
    required this.getCashForecast,
    required this.getAlerts,
    required this.getSuggestions,
  }) : super(FinanceAnalysisInitial());

  Future<void> loadAll() async {
    emit(FinanceAnalysisLoading());

    final results = await Future.wait([
      getRatios(period: _period, branchId: _branchId, comparison: _comparison),
      getRevenue(period: _period, branchId: _branchId, groupBy: 'month'),
      getCosts(period: _period, branchId: _branchId, groupBy: 'month'),
      getBatchProfit(period: _period, branchId: _branchId, limit: 10),
      getCashForecast(months: 3, branchId: _branchId),
      getAlerts(),
      getSuggestions(),
    ]);

    String? error;

    final ratios = results[0].fold((f) {
      error = f.message;
      return null;
    }, (d) => d as FinancialRatioEntity);

    final revenue = results[1].fold((f) {
      error ??= f.message;
      return null;
    }, (d) => d as RevenueAnalysisEntity);

    final costs = results[2].fold((f) {
      error ??= f.message;
      return null;
    }, (d) => d as CostAnalysisEntity);

    final batchProfit = results[3].fold((f) {
      error ??= f.message;
      return null;
    }, (d) => d as BatchProfitAnalysisEntity);

    final cashForecast = results[4].fold((f) {
      error ??= f.message;
      return null;
    }, (d) => d as CashForecastEntity);

    final alerts = results[5].fold(
      (_) => <FinanceAlertEntity>[],
      (d) => d as List<FinanceAlertEntity>,
    );

    final suggestions = results[6].fold(
      (_) => <FinanceAlertEntity>[],
      (d) => d as List<FinanceAlertEntity>,
    );

    if (ratios == null ||
        revenue == null ||
        costs == null ||
        batchProfit == null ||
        cashForecast == null) {
      emit(FinanceAnalysisError(error ?? 'Gagal memuat data analisis keuangan'));
      return;
    }

    emit(FinanceAnalysisLoaded(
      ratios: ratios,
      revenue: revenue,
      costs: costs,
      batchProfit: batchProfit,
      cashForecast: cashForecast,
      alerts: alerts,
      suggestions: suggestions,
      selectedPeriod: _period,
      selectedBranchId: _branchId,
      selectedComparison: _comparison,
    ));
  }

  Future<void> changePeriod(String period) async {
    _period = period;
    await loadAll();
  }

  Future<void> changeBranch(String? branchId) async {
    _branchId = branchId;
    await loadAll();
  }

  Future<void> changeComparison(String comparison) async {
    _comparison = comparison;
    await loadAll();
  }
}
