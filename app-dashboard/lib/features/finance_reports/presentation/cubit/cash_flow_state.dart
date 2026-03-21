part of 'cash_flow_cubit.dart';

abstract class CashFlowState extends Equatable {
  const CashFlowState();
  @override
  List<Object?> get props => [];
}

class CashFlowInitial extends CashFlowState {
  const CashFlowInitial();
}

class CashFlowLoading extends CashFlowState {
  const CashFlowLoading();
}

class CashFlowLoaded extends CashFlowState {
  final CashFlowEntity data;
  final ReportFilterEntity filter;
  const CashFlowLoaded({required this.data, required this.filter});

  @override
  List<Object?> get props => [data, filter];
}

class CashFlowError extends CashFlowState {
  final String message;
  const CashFlowError(this.message);

  @override
  List<Object?> get props => [message];
}
