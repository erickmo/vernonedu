import 'package:equatable/equatable.dart';

class ProfitLossAccountEntity extends Equatable {
  final String code;
  final String name;
  final double amount;
  final List<ProfitLossAccountEntity> children;

  const ProfitLossAccountEntity({
    required this.code,
    required this.name,
    required this.amount,
    this.children = const [],
  });

  @override
  List<Object?> get props => [code, name, amount, children];
}

class MonthlyPLPoint extends Equatable {
  final String label; // e.g. "Jan 26"
  final double revenue;
  final double expense;
  final double netProfit;

  const MonthlyPLPoint({
    required this.label,
    required this.revenue,
    required this.expense,
    required this.netProfit,
  });

  @override
  List<Object?> get props => [label, revenue, expense, netProfit];
}

class ProfitLossEntity extends Equatable {
  final List<ProfitLossAccountEntity> revenueAccounts;
  final List<ProfitLossAccountEntity> cogsAccounts;
  final List<ProfitLossAccountEntity> expenseAccounts;
  final double totalRevenue;
  final double totalCogs;
  final double grossProfit;
  final double totalExpense;
  final double netProfit;
  final List<MonthlyPLPoint> monthlyTrend;

  const ProfitLossEntity({
    required this.revenueAccounts,
    required this.cogsAccounts,
    required this.expenseAccounts,
    required this.totalRevenue,
    required this.totalCogs,
    required this.grossProfit,
    required this.totalExpense,
    required this.netProfit,
    this.monthlyTrend = const [],
  });

  @override
  List<Object?> get props => [
        revenueAccounts,
        cogsAccounts,
        expenseAccounts,
        totalRevenue,
        totalCogs,
        grossProfit,
        totalExpense,
        netProfit,
        monthlyTrend,
      ];
}
