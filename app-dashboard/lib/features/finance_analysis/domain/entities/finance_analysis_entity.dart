import 'package:equatable/equatable.dart';

// --- Financial Ratios -------------------------------------------------------

/// One ratio metric: current value with comparison vs previous period.
class RatioMetric extends Equatable {
  final double current;
  final double previous;
  final double change; // absolute change
  final double changePct; // percentage change
  final String trend; // up, down, flat

  const RatioMetric({
    required this.current,
    required this.previous,
    required this.change,
    required this.changePct,
    required this.trend,
  });

  static const empty = RatioMetric(
    current: 0,
    previous: 0,
    change: 0,
    changePct: 0,
    trend: 'flat',
  );

  @override
  List<Object?> get props => [current, previous, change, changePct, trend];
}

class FinancialRatiosEntity extends Equatable {
  final RatioMetric profitMargin;
  final RatioMetric expenseRatio;
  final RatioMetric revenuePerStudent;
  final RatioMetric costPerStudent;
  final RatioMetric avgBatchProfitability;
  final RatioMetric collectionRate;
  final RatioMetric daysSalesOutstanding;
  final RatioMetric revenueGrowthRate;

  const FinancialRatiosEntity({
    required this.profitMargin,
    required this.expenseRatio,
    required this.revenuePerStudent,
    required this.costPerStudent,
    required this.avgBatchProfitability,
    required this.collectionRate,
    required this.daysSalesOutstanding,
    required this.revenueGrowthRate,
  });

  @override
  List<Object?> get props => [
        profitMargin,
        expenseRatio,
        revenuePerStudent,
        costPerStudent,
        avgBatchProfitability,
        collectionRate,
        daysSalesOutstanding,
        revenueGrowthRate,
      ];
}

// --- Revenue Analysis -------------------------------------------------------

class MonthlyRevenuePoint extends Equatable {
  final String month; // YYYY-MM
  final double total;
  final double regular;
  final double career;
  final double inhouse;
  final double collab;
  final double cert;

  const MonthlyRevenuePoint({
    required this.month,
    required this.total,
    required this.regular,
    required this.career,
    required this.inhouse,
    required this.collab,
    required this.cert,
  });

  @override
  List<Object?> get props => [month, total, regular, career, inhouse, collab, cert];
}

class RevenueByGroup extends Equatable {
  final String groupKey;
  final double revenue;
  final double pctOfTotal;
  final int batchCount;
  final double avgPerBatch;
  final String trend;

  const RevenueByGroup({
    required this.groupKey,
    required this.revenue,
    required this.pctOfTotal,
    required this.batchCount,
    required this.avgPerBatch,
    required this.trend,
  });

  @override
  List<Object?> get props =>
      [groupKey, revenue, pctOfTotal, batchCount, avgPerBatch, trend];
}

class RevenueAnalysisEntity extends Equatable {
  final List<MonthlyRevenuePoint> monthlyTrend;
  final List<RevenueByGroup> byGroup;
  final double totalRevenue;
  final String groupBy;

  const RevenueAnalysisEntity({
    required this.monthlyTrend,
    required this.byGroup,
    required this.totalRevenue,
    required this.groupBy,
  });

  @override
  List<Object?> get props => [monthlyTrend, byGroup, totalRevenue, groupBy];
}

// --- Cost Analysis ----------------------------------------------------------

class MonthlyCostPoint extends Equatable {
  final String month;
  final double total;
  final double facilitator;
  final double commission;
  final double operational;
  final double marketing;
  final double other;

  const MonthlyCostPoint({
    required this.month,
    required this.total,
    required this.facilitator,
    required this.commission,
    required this.operational,
    required this.marketing,
    required this.other,
  });

  @override
  List<Object?> get props =>
      [month, total, facilitator, commission, operational, marketing, other];
}

class CostByCategory extends Equatable {
  final String category;
  final double amount;
  final double pctOfTotal;
  final double vsPrevious;
  final String trend;

  const CostByCategory({
    required this.category,
    required this.amount,
    required this.pctOfTotal,
    required this.vsPrevious,
    required this.trend,
  });

  @override
  List<Object?> get props => [category, amount, pctOfTotal, vsPrevious, trend];
}

class CostAnalysisEntity extends Equatable {
  final List<MonthlyCostPoint> monthlyTrend;
  final List<CostByCategory> byCategory;
  final double totalCost;

  const CostAnalysisEntity({
    required this.monthlyTrend,
    required this.byCategory,
    required this.totalCost,
  });

  @override
  List<Object?> get props => [monthlyTrend, byCategory, totalCost];
}

// --- Batch Profitability ----------------------------------------------------

class BatchProfitItem extends Equatable {
  final String batchId;
  final String batchCode;
  final String courseName;
  final double revenue;
  final double expense;
  final double commission;
  final double profit;
  final double marginPct;

  const BatchProfitItem({
    required this.batchId,
    required this.batchCode,
    required this.courseName,
    required this.revenue,
    required this.expense,
    required this.commission,
    required this.profit,
    required this.marginPct,
  });

  @override
  List<Object?> get props => [
        batchId,
        batchCode,
        courseName,
        revenue,
        expense,
        commission,
        profit,
        marginPct,
      ];
}

class BatchProfitEntity extends Equatable {
  final List<BatchProfitItem> items;
  final double avgMargin;
  final String sort;

  const BatchProfitEntity({
    required this.items,
    required this.avgMargin,
    required this.sort,
  });

  @override
  List<Object?> get props => [items, avgMargin, sort];
}

// --- Cash Forecast ----------------------------------------------------------

class CashForecastMonth extends Equatable {
  final String month;
  final double openingCash;
  final double inflow;
  final double outflow;
  final double closingCash;

  const CashForecastMonth({
    required this.month,
    required this.openingCash,
    required this.inflow,
    required this.outflow,
    required this.closingCash,
  });

  @override
  List<Object?> get props => [month, openingCash, inflow, outflow, closingCash];
}

class CashEvent extends Equatable {
  final String date;
  final String eventType; // inflow, outflow
  final String description;
  final double amount;
  final String status; // confirmed, projected

  const CashEvent({
    required this.date,
    required this.eventType,
    required this.description,
    required this.amount,
    required this.status,
  });

  @override
  List<Object?> get props => [date, eventType, description, amount, status];
}

class CashForecastEntity extends Equatable {
  final double currentCash;
  final List<CashForecastMonth> months;
  final List<CashEvent> upcomingEvents;

  const CashForecastEntity({
    required this.currentCash,
    required this.months,
    required this.upcomingEvents,
  });

  @override
  List<Object?> get props => [currentCash, months, upcomingEvents];
}

// --- Alerts -----------------------------------------------------------------

class FinancialAlert extends Equatable {
  final String level; // warning, info, success (backend) — also used: critical
  final String code;
  final String message;
  final int count;
  final double amount;

  const FinancialAlert({
    required this.level,
    required this.code,
    required this.message,
    this.count = 0,
    this.amount = 0,
  });

  @override
  List<Object?> get props => [level, code, message, count, amount];
}

// --- Suggestions ------------------------------------------------------------

class FinancialSuggestion extends Equatable {
  final String icon;
  final String message;
  final double amount;
  final String detail;

  const FinancialSuggestion({
    required this.icon,
    required this.message,
    this.amount = 0,
    this.detail = '',
  });

  @override
  List<Object?> get props => [icon, message, amount, detail];
}
