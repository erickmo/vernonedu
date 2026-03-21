import '../../domain/entities/profit_loss_entity.dart';

class ProfitLossAccountModel {
  final String code;
  final String name;
  final double amount;
  final List<ProfitLossAccountModel> children;

  const ProfitLossAccountModel({
    required this.code,
    required this.name,
    required this.amount,
    this.children = const [],
  });

  factory ProfitLossAccountModel.fromJson(Map<String, dynamic> json) {
    return ProfitLossAccountModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => ProfitLossAccountModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  ProfitLossAccountEntity toEntity() => ProfitLossAccountEntity(
        code: code,
        name: name,
        amount: amount,
        children: children.map((c) => c.toEntity()).toList(),
      );
}

class MonthlyPLPointModel {
  final String label;
  final double revenue;
  final double expense;
  final double netProfit;

  const MonthlyPLPointModel({
    required this.label,
    required this.revenue,
    required this.expense,
    required this.netProfit,
  });

  factory MonthlyPLPointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyPLPointModel(
      label: json['label']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  MonthlyPLPoint toEntity() => MonthlyPLPoint(
        label: label,
        revenue: revenue,
        expense: expense,
        netProfit: netProfit,
      );
}

class ProfitLossModel {
  final List<ProfitLossAccountModel> revenueAccounts;
  final List<ProfitLossAccountModel> cogsAccounts;
  final List<ProfitLossAccountModel> expenseAccounts;
  final double totalRevenue;
  final double totalCogs;
  final double grossProfit;
  final double totalExpense;
  final double netProfit;
  final List<MonthlyPLPointModel> monthlyTrend;

  const ProfitLossModel({
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

  factory ProfitLossModel.fromJson(Map<String, dynamic> json) {
    return ProfitLossModel(
      revenueAccounts: (json['revenue_accounts'] as List<dynamic>?)
              ?.map((e) => ProfitLossAccountModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cogsAccounts: (json['cogs_accounts'] as List<dynamic>?)
              ?.map((e) => ProfitLossAccountModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      expenseAccounts: (json['expense_accounts'] as List<dynamic>?)
              ?.map((e) => ProfitLossAccountModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCogs: (json['total_cogs'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (json['gross_profit'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0.0,
      monthlyTrend: (json['monthly_trend'] as List<dynamic>?)
              ?.map((e) => MonthlyPLPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory ProfitLossModel.mock() {
    return const ProfitLossModel(
      revenueAccounts: [
        ProfitLossAccountModel(
          code: '4-1000',
          name: 'Pendapatan Kursus',
          amount: 185000000,
          children: [
            ProfitLossAccountModel(
                code: '4-1100', name: 'Pendapatan Program Karir', amount: 95000000),
            ProfitLossAccountModel(
                code: '4-1200', name: 'Pendapatan Kursus Reguler', amount: 60000000),
            ProfitLossAccountModel(
                code: '4-1300', name: 'Pendapatan Privat', amount: 30000000),
          ],
        ),
        ProfitLossAccountModel(
            code: '4-2000', name: 'Pendapatan Lain-lain', amount: 15000000),
      ],
      cogsAccounts: [
        ProfitLossAccountModel(
            code: '5-1000', name: 'Biaya Fasilitator', amount: 55000000),
        ProfitLossAccountModel(
            code: '5-2000', name: 'Biaya Bahan Ajar', amount: 12000000),
      ],
      expenseAccounts: [
        ProfitLossAccountModel(
            code: '6-1000', name: 'Gaji Karyawan', amount: 65000000),
        ProfitLossAccountModel(
            code: '6-2000', name: 'Sewa Gedung & Utilitas', amount: 25000000),
        ProfitLossAccountModel(
            code: '6-3000', name: 'Biaya Marketing', amount: 8000000),
        ProfitLossAccountModel(
            code: '6-4000', name: 'Biaya Operasional Lain', amount: 5000000),
      ],
      totalRevenue: 200000000,
      totalCogs: 67000000,
      grossProfit: 133000000,
      totalExpense: 103000000,
      netProfit: 30000000,
      monthlyTrend: [
        MonthlyPLPointModel(
            label: 'Okt 25', revenue: 160000000, expense: 135000000, netProfit: 25000000),
        MonthlyPLPointModel(
            label: 'Nov 25', revenue: 175000000, expense: 142000000, netProfit: 33000000),
        MonthlyPLPointModel(
            label: 'Des 25', revenue: 190000000, expense: 155000000, netProfit: 35000000),
        MonthlyPLPointModel(
            label: 'Jan 26', revenue: 168000000, expense: 140000000, netProfit: 28000000),
        MonthlyPLPointModel(
            label: 'Feb 26', revenue: 185000000, expense: 148000000, netProfit: 37000000),
        MonthlyPLPointModel(
            label: 'Mar 26', revenue: 200000000, expense: 170000000, netProfit: 30000000),
      ],
    );
  }

  ProfitLossEntity toEntity() => ProfitLossEntity(
        revenueAccounts: revenueAccounts.map((a) => a.toEntity()).toList(),
        cogsAccounts: cogsAccounts.map((a) => a.toEntity()).toList(),
        expenseAccounts: expenseAccounts.map((a) => a.toEntity()).toList(),
        totalRevenue: totalRevenue,
        totalCogs: totalCogs,
        grossProfit: grossProfit,
        totalExpense: totalExpense,
        netProfit: netProfit,
        monthlyTrend: monthlyTrend.map((p) => p.toEntity()).toList(),
      );
}
