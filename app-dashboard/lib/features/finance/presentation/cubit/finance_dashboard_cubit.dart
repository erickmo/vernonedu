import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../features/accounting/domain/entities/accounting_stats_entity.dart';
import '../../../../features/accounting/domain/entities/transaction_entity.dart';
import '../../../../features/accounting/domain/entities/invoice_entity.dart';
import '../../../../features/accounting/domain/entities/budget_item_entity.dart';
import '../../../../features/accounting/domain/usecases/get_accounting_stats_usecase.dart';
import '../../../../features/accounting/domain/usecases/get_transactions_usecase.dart';
import '../../../../features/accounting/domain/usecases/get_invoices_usecase.dart';
import '../../../../features/accounting/domain/usecases/get_budget_vs_actual_usecase.dart';
import '../../../../features/accounting/domain/usecases/create_transaction_usecase.dart';
import '../../../../features/accounting/domain/usecases/update_invoice_status_usecase.dart';

part 'finance_dashboard_state.dart';

class FinanceDashboardCubit extends Cubit<FinanceDashboardState> {
  final GetAccountingStatsUseCase _getStats;
  final GetTransactionsUseCase _getTransactions;
  final GetInvoicesUseCase _getInvoices;
  final GetBudgetVsActualUseCase _getBudgetVsActual;
  final CreateTransactionUseCase _createTransaction;
  final UpdateInvoiceStatusUseCase _updateInvoiceStatus;

  FinanceDashboardCubit({
    required GetAccountingStatsUseCase getStatsUseCase,
    required GetTransactionsUseCase getTransactionsUseCase,
    required GetInvoicesUseCase getInvoicesUseCase,
    required GetBudgetVsActualUseCase getBudgetVsActualUseCase,
    required CreateTransactionUseCase createTransactionUseCase,
    required UpdateInvoiceStatusUseCase updateInvoiceStatusUseCase,
  })  : _getStats = getStatsUseCase,
        _getTransactions = getTransactionsUseCase,
        _getInvoices = getInvoicesUseCase,
        _getBudgetVsActual = getBudgetVsActualUseCase,
        _createTransaction = createTransactionUseCase,
        _updateInvoiceStatus = updateInvoiceStatusUseCase,
        super(const FinanceDashboardInitial());

  Future<void> loadAll({int? month, int? year}) async {
    emit(const FinanceDashboardLoading());
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    // Build last-6-months periods for trend chart
    final trendPeriods = <({int month, int year, String label})>[];
    for (int i = 5; i >= 0; i--) {
      final dt = DateTime(y, m - i, 1);
      trendPeriods.add((
        month: dt.month,
        year: dt.year,
        label: DateFormat('MMM yy').format(dt),
      ));
    }

    // Parallel load: current stats, transactions, invoices, budget, + 6-month trend
    final futures = <Future>[
      _getStats(month: m, year: y),
      _getTransactions(offset: 0, limit: 20, month: m, year: y),
      _getInvoices(offset: 0, limit: 100, month: m, year: y),
      _getBudgetVsActual(month: m, year: y),
      ...trendPeriods.map((p) => _getStats(month: p.month, year: p.year)),
    ];

    final results = await Future.wait(futures);

    final statsResult = results[0];
    final stats = statsResult.fold((_) => null, (d) => d as AccountingStatsEntity?);
    if (stats == null) {
      final msg = statsResult.fold((f) => f.message, (_) => 'Unknown error');
      emit(FinanceDashboardError(msg));
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
    final budgetItems = results[3].fold(
      (_) => <BudgetItemEntity>[],
      (d) => d as List<BudgetItemEntity>,
    );

    final trend = <MonthlyTrendPoint>[];
    for (int i = 0; i < trendPeriods.length; i++) {
      final trendStats = results[4 + i].fold(
        (_) => null,
        (d) => d as AccountingStatsEntity?,
      );
      trend.add(MonthlyTrendPoint(
        label: trendPeriods[i].label,
        revenue: trendStats?.totalRevenue ?? 0,
        expense: trendStats?.totalExpense ?? 0,
      ));
    }

    emit(FinanceDashboardLoaded(
      stats: stats,
      transactions: transactions,
      invoices: invoices,
      budgetItems: budgetItems,
      monthlyTrend: trend,
      selectedMonth: m,
      selectedYear: y,
    ));
  }

  Future<bool> createTransaction({required Map<String, dynamic> body}) async {
    final result = await _createTransaction(body: body);
    return result.fold(
      (failure) {
        emit(FinanceDashboardError(failure.message));
        return false;
      },
      (_) {
        final s = state;
        if (s is FinanceDashboardLoaded) {
          loadAll(month: s.selectedMonth, year: s.selectedYear);
        }
        return true;
      },
    );
  }

  Future<void> updateInvoiceStatus({
    required String id,
    required String status,
  }) async {
    final result = await _updateInvoiceStatus(id: id, status: status);
    result.fold(
      (f) => emit(FinanceDashboardError(f.message)),
      (_) {
        if (state is FinanceDashboardLoaded) {
          final s = state as FinanceDashboardLoaded;
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
          emit(FinanceDashboardLoaded(
            stats: s.stats,
            transactions: s.transactions,
            invoices: updated,
            budgetItems: s.budgetItems,
            monthlyTrend: s.monthlyTrend,
            selectedMonth: s.selectedMonth,
            selectedYear: s.selectedYear,
          ));
        }
      },
    );
  }
}
