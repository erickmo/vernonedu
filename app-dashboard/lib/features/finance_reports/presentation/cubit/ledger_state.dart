part of 'ledger_cubit.dart';

abstract class LedgerState extends Equatable {
  const LedgerState();
  @override
  List<Object?> get props => [];
}

class LedgerInitial extends LedgerState {
  const LedgerInitial();
}

class LedgerLoading extends LedgerState {
  const LedgerLoading();
}

class LedgerLoaded extends LedgerState {
  final LedgerEntity data;
  final ReportFilterEntity filter;
  const LedgerLoaded({required this.data, required this.filter});

  @override
  List<Object?> get props => [data, filter];
}

class LedgerError extends LedgerState {
  final String message;
  const LedgerError(this.message);

  @override
  List<Object?> get props => [message];
}
