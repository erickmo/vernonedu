import '../../domain/entities/accounting_stats_entity.dart';

class AccountingStatsModel extends AccountingStatsEntity {
  const AccountingStatsModel({
    required super.totalRevenue,
    required super.totalExpense,
    required super.netProfit,
    required super.cashAndBank,
    required super.receivables,
    required super.payables,
  });

  factory AccountingStatsModel.fromJson(Map<String, dynamic> json) =>
      AccountingStatsModel(
        totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
        totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0,
        netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0,
        cashAndBank: (json['cash_and_bank'] as num?)?.toDouble() ?? 0,
        receivables: (json['receivables'] as num?)?.toDouble() ?? 0,
        payables: (json['payables'] as num?)?.toDouble() ?? 0,
      );

  AccountingStatsEntity toEntity() => AccountingStatsEntity(
        totalRevenue: totalRevenue,
        totalExpense: totalExpense,
        netProfit: netProfit,
        cashAndBank: cashAndBank,
        receivables: receivables,
        payables: payables,
      );
}
