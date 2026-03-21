part of 'trial_balance_cubit.dart';

abstract class TrialBalanceState extends Equatable {
  const TrialBalanceState();
  @override
  List<Object?> get props => [];
}

class TrialBalanceInitial extends TrialBalanceState {
  const TrialBalanceInitial();
}

class TrialBalanceLoading extends TrialBalanceState {
  const TrialBalanceLoading();
}

class TrialBalanceLoaded extends TrialBalanceState {
  final TrialBalanceEntity data;
  final ReportFilterEntity filter;
  const TrialBalanceLoaded({required this.data, required this.filter});

  @override
  List<Object?> get props => [data, filter];
}

class TrialBalanceError extends TrialBalanceState {
  final String message;
  const TrialBalanceError(this.message);

  @override
  List<Object?> get props => [message];
}
