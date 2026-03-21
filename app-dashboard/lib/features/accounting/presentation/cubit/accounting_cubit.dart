import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/accounting_stats_entity.dart';
import '../../domain/entities/budget_item_entity.dart';
import '../../domain/entities/coa_entity.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/create_transaction_usecase.dart';
import '../../domain/usecases/get_accounting_stats_usecase.dart';
import '../../domain/usecases/get_budget_vs_actual_usecase.dart';
import '../../domain/usecases/get_coa_usecase.dart';
import '../../domain/usecases/get_invoices_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/update_invoice_status_usecase.dart';

part 'accounting_state.dart';

class AccountingCubit extends Cubit<AccountingState> {
  final GetAccountingStatsUseCase getStatsUseCase;
  final GetTransactionsUseCase getTransactionsUseCase;
  final CreateTransactionUseCase createTransactionUseCase;
  final GetInvoicesUseCase getInvoicesUseCase;
  final UpdateInvoiceStatusUseCase updateInvoiceStatusUseCase;
  final GetCoaUseCase getCoaUseCase;
  final GetBudgetVsActualUseCase getBudgetVsActualUseCase;

  AccountingCubit({
    required this.getStatsUseCase,
    required this.getTransactionsUseCase,
    required this.createTransactionUseCase,
    required this.getInvoicesUseCase,
    required this.updateInvoiceStatusUseCase,
    required this.getCoaUseCase,
    required this.getBudgetVsActualUseCase,
  }) : super(const AccountingInitial());

  Future<void> loadAll({int? month, int? year}) async {
    emit(const AccountingLoading());
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    final results = await Future.wait([
      getStatsUseCase(month: m, year: y),
      getTransactionsUseCase(offset: 0, limit: 20, month: m, year: y),
      getInvoicesUseCase(offset: 0, limit: 20, month: m, year: y),
      getCoaUseCase(),
      getBudgetVsActualUseCase(month: m, year: y),
    ]);

    final statsResult = results[0];
    final stats = statsResult.fold((_) => null, (d) => d as AccountingStatsEntity?);
    if (stats == null) {
      final failure = statsResult.fold((f) => f.message, (_) => 'Unknown error');
      emit(AccountingError(failure));
      return;
    }

    final transactions = results[1].fold(
      (_) => <TransactionEntity>[],
      (d) => d as List<TransactionEntity>,
    );
    final invoices = results[2].fold(
      (_) => <InvoiceEntity>[],
      (d) => d as List<InvoiceEntity>,
    );
    final coa = results[3].fold(
      (_) => <CoaEntity>[],
      (d) => d as List<CoaEntity>,
    );
    final budgetItems = results[4].fold(
      (_) => <BudgetItemEntity>[],
      (d) => d as List<BudgetItemEntity>,
    );

    emit(AccountingLoaded(
      stats: stats,
      transactions: transactions,
      invoices: invoices,
      coa: coa,
      budgetItems: budgetItems,
    ));
  }

  Future<bool> createTransaction({required Map<String, dynamic> body}) async {
    final result = await createTransactionUseCase(body: body);
    return result.fold(
      (failure) {
        emit(AccountingError(failure.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<void> updateInvoiceStatus({
    required String id,
    required String status,
  }) async {
    final result = await updateInvoiceStatusUseCase(id: id, status: status);
    result.fold(
      (failure) => emit(AccountingError(failure.message)),
      (_) {
        if (state is AccountingLoaded) {
          final s = state as AccountingLoaded;
          final updated = s.invoices
              .map((inv) => inv.id == id
                  ? InvoiceEntity(
                      id: inv.id,
                      invoiceNumber: inv.invoiceNumber,
                      studentName: inv.studentName,
                      batchName: inv.batchName,
                      paymentMethod: inv.paymentMethod,
                      amount: inv.amount,
                      dueDate: inv.dueDate,
                      status: status,
                      createdAt: inv.createdAt,
                    )
                  : inv)
              .toList();
          emit(AccountingLoaded(
            stats: s.stats,
            transactions: s.transactions,
            invoices: updated,
            coa: s.coa,
            budgetItems: s.budgetItems,
          ));
        }
      },
    );
  }
}
