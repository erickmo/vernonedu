part of 'profit_loss_cubit.dart';

abstract class ProfitLossState extends Equatable {
  const ProfitLossState();
  @override
  List<Object?> get props => [];
}

class ProfitLossInitial extends ProfitLossState {
  const ProfitLossInitial();
}

class ProfitLossLoading extends ProfitLossState {
  const ProfitLossLoading();
}

class ProfitLossLoaded extends ProfitLossState {
  final ProfitLossEntity data;
  final ReportFilterEntity filter;
  const ProfitLossLoaded({required this.data, required this.filter});

  @override
  List<Object?> get props => [data, filter];
}

class ProfitLossError extends ProfitLossState {
  final String message;
  const ProfitLossError(this.message);

  @override
  List<Object?> get props => [message];
}
