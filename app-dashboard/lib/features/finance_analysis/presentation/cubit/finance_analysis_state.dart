import 'package:equatable/equatable.dart';
import '../../domain/entities/finance_analysis_entity.dart';

abstract class FinanceAnalysisState extends Equatable {
  const FinanceAnalysisState();

  @override
  List<Object?> get props => [];
}

class FinanceAnalysisInitial extends FinanceAnalysisState {}

class FinanceAnalysisLoading extends FinanceAnalysisState {}

class FinanceAnalysisLoaded extends FinanceAnalysisState {
  final FinancialRatioEntity ratios;
  final RevenueAnalysisEntity revenue;
  final CostAnalysisEntity costs;
  final BatchProfitAnalysisEntity batchProfit;
  final CashForecastEntity cashForecast;
  final List<FinanceAlertEntity> alerts;
  final List<FinanceAlertEntity> suggestions;
  final String selectedPeriod;
  final String? selectedBranchId;
  final String selectedComparison;

  const FinanceAnalysisLoaded({
    required this.ratios,
    required this.revenue,
    required this.costs,
    required this.batchProfit,
    required this.cashForecast,
    required this.alerts,
    required this.suggestions,
    required this.selectedPeriod,
    this.selectedBranchId,
    required this.selectedComparison,
  });

  @override
  List<Object?> get props => [
        ratios,
        revenue,
        costs,
        batchProfit,
        cashForecast,
        alerts,
        suggestions,
        selectedPeriod,
        selectedBranchId,
        selectedComparison,
      ];
}

class FinanceAnalysisError extends FinanceAnalysisState {
  final String message;

  const FinanceAnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}
