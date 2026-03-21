import 'package:equatable/equatable.dart';

class AccountingStatsEntity extends Equatable {
  final double totalRevenue;
  final double totalExpense;
  final double netProfit;
  final double cashAndBank;
  final double receivables;
  final double payables;

  const AccountingStatsEntity({
    required this.totalRevenue,
    required this.totalExpense,
    required this.netProfit,
    required this.cashAndBank,
    required this.receivables,
    required this.payables,
  });

  @override
  List<Object?> get props => [
        totalRevenue,
        totalExpense,
        netProfit,
        cashAndBank,
        receivables,
        payables,
      ];
}
