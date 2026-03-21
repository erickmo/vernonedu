part of 'accounting_cubit.dart';

abstract class AccountingState extends Equatable {
  const AccountingState();

  @override
  List<Object?> get props => [];
}

class AccountingInitial extends AccountingState {
  const AccountingInitial();
}

class AccountingLoading extends AccountingState {
  const AccountingLoading();
}

class AccountingLoaded extends AccountingState {
  final AccountingStatsEntity stats;
  final List<TransactionEntity> transactions;
  final List<InvoiceEntity> invoices;
  final List<CoaEntity> coa;
  final List<BudgetItemEntity> budgetItems;

  const AccountingLoaded({
    required this.stats,
    required this.transactions,
    required this.invoices,
    required this.coa,
    required this.budgetItems,
  });

  @override
  List<Object?> get props => [stats, transactions, invoices, coa, budgetItems];
}

class AccountingError extends AccountingState {
  final String message;

  const AccountingError(this.message);

  @override
  List<Object?> get props => [message];
}
