part of 'finance_dashboard_cubit.dart';

class MonthlyTrendPoint {
  final String label; // e.g. "Jan 26"
  final double revenue;
  final double expense;

  const MonthlyTrendPoint({
    required this.label,
    required this.revenue,
    required this.expense,
  });
}

class BatchSummary {
  final String batchName;
  final double revenue;
  final double expense;
  final double commission;

  const BatchSummary({
    required this.batchName,
    required this.revenue,
    required this.expense,
    required this.commission,
  });

  double get profit => revenue - expense - commission;
  double get margin => revenue > 0 ? (profit / revenue) * 100 : 0;
}

abstract class FinanceDashboardState extends Equatable {
  const FinanceDashboardState();

  @override
  List<Object?> get props => [];
}

class FinanceDashboardInitial extends FinanceDashboardState {
  const FinanceDashboardInitial();
}

class FinanceDashboardLoading extends FinanceDashboardState {
  const FinanceDashboardLoading();
}

class FinanceDashboardLoaded extends FinanceDashboardState {
  final AccountingStatsEntity stats;
  final List<TransactionEntity> transactions;
  final List<InvoiceEntity> invoices;
  final List<BudgetItemEntity> budgetItems;
  final List<MonthlyTrendPoint> monthlyTrend;
  final int selectedMonth;
  final int selectedYear;

  const FinanceDashboardLoaded({
    required this.stats,
    required this.transactions,
    required this.invoices,
    required this.budgetItems,
    required this.monthlyTrend,
    required this.selectedMonth,
    required this.selectedYear,
  });

  // Derived data
  int get dueThisWeekCount {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return invoices.where((inv) {
      final isPending = inv.status == 'pending' || inv.status == 'overdue';
      try {
        final due = DateTime.parse(inv.dueDate);
        return isPending && due.isBefore(nextWeek);
      } catch (_) {
        return false;
      }
    }).length;
  }

  List<BatchSummary> get batchSummaries {
    final map = <String, BatchSummary>{};
    for (final inv in invoices) {
      final name = inv.batchName.isEmpty ? '-' : inv.batchName;
      final existing = map[name];
      final revenue = inv.status != 'cancelled' ? inv.amount : 0.0;
      map[name] = BatchSummary(
        batchName: name,
        revenue: (existing?.revenue ?? 0) + revenue,
        expense: existing?.expense ?? 0,
        commission: existing?.commission ?? 0,
      );
    }
    return map.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
  }

  @override
  List<Object?> get props => [stats, transactions, invoices, budgetItems, monthlyTrend, selectedMonth, selectedYear];
}

class FinanceDashboardError extends FinanceDashboardState {
  final String message;
  const FinanceDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
