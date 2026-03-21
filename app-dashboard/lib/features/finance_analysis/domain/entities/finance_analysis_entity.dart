import 'package:equatable/equatable.dart';

class FinancialRatioEntity extends Equatable {
  final double profitMargin;
  final double profitMarginTrend;
  final double opexRatio;
  final double opexRatioTrend;
  final double revenuePerStudent;
  final double revenuePerStudentTrend;
  final double costPerStudent;
  final double costPerStudentTrend;
  final double avgBatchProfitability;
  final double avgBatchProfitabilityTrend;
  final double collectionRate;
  final double collectionRateTrend;
  final double dso;
  final double dsoTrend;
  final double revenueGrowthRate;
  final double revenueGrowthRateTrend;

  const FinancialRatioEntity({
    required this.profitMargin,
    required this.profitMarginTrend,
    required this.opexRatio,
    required this.opexRatioTrend,
    required this.revenuePerStudent,
    required this.revenuePerStudentTrend,
    required this.costPerStudent,
    required this.costPerStudentTrend,
    required this.avgBatchProfitability,
    required this.avgBatchProfitabilityTrend,
    required this.collectionRate,
    required this.collectionRateTrend,
    required this.dso,
    required this.dsoTrend,
    required this.revenueGrowthRate,
    required this.revenueGrowthRateTrend,
  });

  @override
  List<Object?> get props => [
        profitMargin,
        opexRatio,
        revenuePerStudent,
        costPerStudent,
        avgBatchProfitability,
        collectionRate,
        dso,
        revenueGrowthRate,
      ];
}

class RevenueTrendPoint extends Equatable {
  final String month;
  final double total;
  final double reguler;
  final double programKarir;
  final double inhouse;
  final double kolaborasi;
  final double sertifikasi;

  const RevenueTrendPoint({
    required this.month,
    required this.total,
    required this.reguler,
    required this.programKarir,
    required this.inhouse,
    required this.kolaborasi,
    required this.sertifikasi,
  });

  @override
  List<Object?> get props => [month, total];
}

class RevenueByTypeEntity extends Equatable {
  final String typeName;
  final double amount;
  final double percentage;
  final int batchCount;
  final double avgPerBatch;
  final double trend;

  const RevenueByTypeEntity({
    required this.typeName,
    required this.amount,
    required this.percentage,
    required this.batchCount,
    required this.avgPerBatch,
    required this.trend,
  });

  @override
  List<Object?> get props => [typeName, amount];
}

class RevenueByBranchEntity extends Equatable {
  final String branchName;
  final double amount;

  const RevenueByBranchEntity({required this.branchName, required this.amount});

  @override
  List<Object?> get props => [branchName, amount];
}

class RevenueAnalysisEntity extends Equatable {
  final List<RevenueTrendPoint> trend;
  final List<RevenueByTypeEntity> byType;
  final List<RevenueByBranchEntity> byBranch;

  const RevenueAnalysisEntity({
    required this.trend,
    required this.byType,
    required this.byBranch,
  });

  @override
  List<Object?> get props => [trend, byType, byBranch];
}

class CostTrendPoint extends Equatable {
  final String month;
  final double facilitator;
  final double commission;
  final double operational;
  final double marketing;
  final double investment;
  final double total;

  const CostTrendPoint({
    required this.month,
    required this.facilitator,
    required this.commission,
    required this.operational,
    required this.marketing,
    required this.investment,
    required this.total,
  });

  @override
  List<Object?> get props => [month, total];
}

class CostByCategory extends Equatable {
  final String category;
  final double amount;
  final double percentage;
  final double vsLastMonth;
  final double trend;

  const CostByCategory({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.vsLastMonth,
    required this.trend,
  });

  @override
  List<Object?> get props => [category, amount];
}

class CostAnalysisEntity extends Equatable {
  final List<CostTrendPoint> trend;
  final List<CostByCategory> byCategory;

  const CostAnalysisEntity({required this.trend, required this.byCategory});

  @override
  List<Object?> get props => [trend, byCategory];
}

class BatchProfitEntity extends Equatable {
  final String batchCode;
  final String courseName;
  final double revenue;
  final double expenditure;
  final double commission;
  final double profit;
  final double marginPercent;

  const BatchProfitEntity({
    required this.batchCode,
    required this.courseName,
    required this.revenue,
    required this.expenditure,
    required this.commission,
    required this.profit,
    required this.marginPercent,
  });

  @override
  List<Object?> get props => [batchCode, marginPercent];
}

class HistogramBucket extends Equatable {
  final String rangeLabel;
  final int count;

  const HistogramBucket({required this.rangeLabel, required this.count});

  @override
  List<Object?> get props => [rangeLabel, count];
}

class BatchProfitAnalysisEntity extends Equatable {
  final List<BatchProfitEntity> topBatches;
  final List<BatchProfitEntity> bottomBatches;
  final List<HistogramBucket> histogram;

  const BatchProfitAnalysisEntity({
    required this.topBatches,
    required this.bottomBatches,
    required this.histogram,
  });

  @override
  List<Object?> get props => [topBatches, bottomBatches];
}

class CashForecastPoint extends Equatable {
  final String month;
  final double projectedCash;
  final double projectedInflow;
  final double projectedOutflow;

  const CashForecastPoint({
    required this.month,
    required this.projectedCash,
    required this.projectedInflow,
    required this.projectedOutflow,
  });

  @override
  List<Object?> get props => [month, projectedCash];
}

class CashEventEntity extends Equatable {
  final String date;
  final String type;
  final String description;
  final double amount;
  final String status;

  const CashEventEntity({
    required this.date,
    required this.type,
    required this.description,
    required this.amount,
    required this.status,
  });

  @override
  List<Object?> get props => [date, description, amount];
}

class CashForecastEntity extends Equatable {
  final List<CashForecastPoint> projection;
  final List<CashEventEntity> upcomingEvents;

  const CashForecastEntity({
    required this.projection,
    required this.upcomingEvents,
  });

  @override
  List<Object?> get props => [projection, upcomingEvents];
}

class FinanceAlertEntity extends Equatable {
  final String type; // 'warning' | 'info' | 'success'
  final String message;

  const FinanceAlertEntity({required this.type, required this.message});

  @override
  List<Object?> get props => [type, message];
}
