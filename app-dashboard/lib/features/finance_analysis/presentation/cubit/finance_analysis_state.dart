import 'package:equatable/equatable.dart';
import '../../domain/entities/finance_analysis_entity.dart';

abstract class FinanceAnalysisState extends Equatable {
  const FinanceAnalysisState();

  @override
  List<Object?> get props => [];
}

class FinanceAnalysisInitial extends FinanceAnalysisState {
  const FinanceAnalysisInitial();
}

class FinanceAnalysisLoading extends FinanceAnalysisState {
  const FinanceAnalysisLoading();
}

class FinanceAnalysisLoaded extends FinanceAnalysisState {
  final FinancialRatiosEntity ratios;
  final RevenueAnalysisEntity revenue;
  final CostAnalysisEntity costs;
  final BatchProfitEntity batchProfit;
  final CashForecastEntity cashForecast;
  final List<FinancialAlert> alerts;
  final List<FinancialSuggestion> suggestions;

  const FinanceAnalysisLoaded({
    required this.ratios,
    required this.revenue,
    required this.costs,
    required this.batchProfit,
    required this.cashForecast,
    required this.alerts,
    required this.suggestions,
  });

  @override
  List<Object?> get props =>
      [ratios, revenue, costs, batchProfit, cashForecast, alerts, suggestions];
}

class FinanceAnalysisError extends FinanceAnalysisState {
  final String message;

  const FinanceAnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}
