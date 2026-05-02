import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '../../domain/usecases/get_batch_profit_analysis_usecase.dart';
import '../../domain/usecases/get_cash_forecast_usecase.dart';
import '../../domain/usecases/get_cost_analysis_usecase.dart';
import '../../domain/usecases/get_finance_alerts_usecase.dart';
import '../../domain/usecases/get_finance_suggestions_usecase.dart';
import '../../domain/usecases/get_financial_ratios_usecase.dart';
import '../../domain/usecases/get_revenue_analysis_usecase.dart';
import 'finance_analysis_state.dart';

class FinanceAnalysisCubit extends Cubit<FinanceAnalysisState> {
  final GetFinancialRatiosUseCase getRatios;
  final GetRevenueAnalysisUseCase getRevenue;
  final GetCostAnalysisUseCase getCosts;
  final GetBatchProfitAnalysisUseCase getBatchProfit;
  final GetCashForecastUseCase getCashForecast;
  final GetFinanceAlertsUseCase getAlerts;
  final GetFinanceSuggestionsUseCase getSuggestions;

  FinanceAnalysisCubit({
    required this.getRatios,
    required this.getRevenue,
    required this.getCosts,
    required this.getBatchProfit,
    required this.getCashForecast,
    required this.getAlerts,
    required this.getSuggestions,
  }) : super(const FinanceAnalysisInitial());

  /// Loads all 7 analysis endpoints in parallel.
  /// On any Left → emits Error with combined messages; otherwise emits Loaded.
  Future<void> loadAll() async {
    emit(const FinanceAnalysisLoading());

    final results = await Future.wait([
      getRatios(),
      getRevenue(),
      getCosts(),
      getBatchProfit(),
      getCashForecast(),
      getAlerts(),
      getSuggestions(),
    ]);

    final errors = <String>[];
    FinancialRatiosEntity? ratios;
    RevenueAnalysisEntity? revenue;
    CostAnalysisEntity? costs;
    BatchProfitEntity? batchProfit;
    CashForecastEntity? cashForecast;
    List<FinancialAlert> alerts = const [];
    List<FinancialSuggestion> suggestions = const [];

    results[0].fold((f) => errors.add(f.message),
        (d) => ratios = d as FinancialRatiosEntity);
    results[1].fold((f) => errors.add(f.message),
        (d) => revenue = d as RevenueAnalysisEntity);
    results[2].fold((f) => errors.add(f.message),
        (d) => costs = d as CostAnalysisEntity);
    results[3].fold((f) => errors.add(f.message),
        (d) => batchProfit = d as BatchProfitEntity);
    results[4].fold((f) => errors.add(f.message),
        (d) => cashForecast = d as CashForecastEntity);
    results[5].fold((f) => errors.add(f.message),
        (d) => alerts = d as List<FinancialAlert>);
    results[6].fold((f) => errors.add(f.message),
        (d) => suggestions = d as List<FinancialSuggestion>);

    if (errors.isNotEmpty ||
        ratios == null ||
        revenue == null ||
        costs == null ||
        batchProfit == null ||
        cashForecast == null) {
      emit(FinanceAnalysisError(
        errors.isEmpty ? 'Gagal memuat analisis keuangan' : errors.join(' • '),
      ));
      return;
    }

    emit(FinanceAnalysisLoaded(
      ratios: ratios!,
      revenue: revenue!,
      costs: costs!,
      batchProfit: batchProfit!,
      cashForecast: cashForecast!,
      alerts: alerts,
      suggestions: suggestions,
    ));
  }
}
