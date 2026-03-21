part of 'balance_sheet_cubit.dart';

abstract class BalanceSheetState extends Equatable {
  const BalanceSheetState();
  @override
  List<Object?> get props => [];
}

class BalanceSheetInitial extends BalanceSheetState {
  const BalanceSheetInitial();
}

class BalanceSheetLoading extends BalanceSheetState {
  const BalanceSheetLoading();
}

class BalanceSheetLoaded extends BalanceSheetState {
  final BalanceSheetEntity data;
  final ReportFilterEntity filter;
  const BalanceSheetLoaded({required this.data, required this.filter});

  @override
  List<Object?> get props => [data, filter];
}

class BalanceSheetError extends BalanceSheetState {
  final String message;
  const BalanceSheetError(this.message);

  @override
  List<Object?> get props => [message];
}
