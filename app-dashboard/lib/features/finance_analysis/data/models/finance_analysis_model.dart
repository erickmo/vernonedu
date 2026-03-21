import '../../domain/entities/finance_analysis_entity.dart';

class FinancialRatioModel {
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

  const FinancialRatioModel({
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

  factory FinancialRatioModel.fromJson(Map<String, dynamic> json) {
    return FinancialRatioModel(
      profitMargin: (json['profit_margin'] as num?)?.toDouble() ?? 0.0,
      profitMarginTrend: (json['profit_margin_trend'] as num?)?.toDouble() ?? 0.0,
      opexRatio: (json['opex_ratio'] as num?)?.toDouble() ?? 0.0,
      opexRatioTrend: (json['opex_ratio_trend'] as num?)?.toDouble() ?? 0.0,
      revenuePerStudent: (json['revenue_per_student'] as num?)?.toDouble() ?? 0.0,
      revenuePerStudentTrend: (json['revenue_per_student_trend'] as num?)?.toDouble() ?? 0.0,
      costPerStudent: (json['cost_per_student'] as num?)?.toDouble() ?? 0.0,
      costPerStudentTrend: (json['cost_per_student_trend'] as num?)?.toDouble() ?? 0.0,
      avgBatchProfitability: (json['avg_batch_profitability'] as num?)?.toDouble() ?? 0.0,
      avgBatchProfitabilityTrend: (json['avg_batch_profitability_trend'] as num?)?.toDouble() ?? 0.0,
      collectionRate: (json['collection_rate'] as num?)?.toDouble() ?? 0.0,
      collectionRateTrend: (json['collection_rate_trend'] as num?)?.toDouble() ?? 0.0,
      dso: (json['dso'] as num?)?.toDouble() ?? 0.0,
      dsoTrend: (json['dso_trend'] as num?)?.toDouble() ?? 0.0,
      revenueGrowthRate: (json['revenue_growth_rate'] as num?)?.toDouble() ?? 0.0,
      revenueGrowthRateTrend: (json['revenue_growth_rate_trend'] as num?)?.toDouble() ?? 0.0,
    );
  }

  FinancialRatioEntity toEntity() => FinancialRatioEntity(
        profitMargin: profitMargin,
        profitMarginTrend: profitMarginTrend,
        opexRatio: opexRatio,
        opexRatioTrend: opexRatioTrend,
        revenuePerStudent: revenuePerStudent,
        revenuePerStudentTrend: revenuePerStudentTrend,
        costPerStudent: costPerStudent,
        costPerStudentTrend: costPerStudentTrend,
        avgBatchProfitability: avgBatchProfitability,
        avgBatchProfitabilityTrend: avgBatchProfitabilityTrend,
        collectionRate: collectionRate,
        collectionRateTrend: collectionRateTrend,
        dso: dso,
        dsoTrend: dsoTrend,
        revenueGrowthRate: revenueGrowthRate,
        revenueGrowthRateTrend: revenueGrowthRateTrend,
      );
}

class RevenueTrendPointModel {
  final String month;
  final double total;
  final double reguler;
  final double programKarir;
  final double inhouse;
  final double kolaborasi;
  final double sertifikasi;

  const RevenueTrendPointModel({
    required this.month,
    required this.total,
    required this.reguler,
    required this.programKarir,
    required this.inhouse,
    required this.kolaborasi,
    required this.sertifikasi,
  });

  factory RevenueTrendPointModel.fromJson(Map<String, dynamic> json) {
    return RevenueTrendPointModel(
      month: json['month']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      reguler: (json['reguler'] as num?)?.toDouble() ?? 0.0,
      programKarir: (json['program_karir'] as num?)?.toDouble() ?? 0.0,
      inhouse: (json['inhouse'] as num?)?.toDouble() ?? 0.0,
      kolaborasi: (json['kolaborasi'] as num?)?.toDouble() ?? 0.0,
      sertifikasi: (json['sertifikasi'] as num?)?.toDouble() ?? 0.0,
    );
  }

  RevenueTrendPoint toEntity() => RevenueTrendPoint(
        month: month,
        total: total,
        reguler: reguler,
        programKarir: programKarir,
        inhouse: inhouse,
        kolaborasi: kolaborasi,
        sertifikasi: sertifikasi,
      );
}

class RevenueByTypeModel {
  final String typeName;
  final double amount;
  final double percentage;
  final int batchCount;
  final double avgPerBatch;
  final double trend;

  const RevenueByTypeModel({
    required this.typeName,
    required this.amount,
    required this.percentage,
    required this.batchCount,
    required this.avgPerBatch,
    required this.trend,
  });

  factory RevenueByTypeModel.fromJson(Map<String, dynamic> json) {
    return RevenueByTypeModel(
      typeName: json['type_name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      batchCount: (json['batch_count'] as num?)?.toInt() ?? 0,
      avgPerBatch: (json['avg_per_batch'] as num?)?.toDouble() ?? 0.0,
      trend: (json['trend'] as num?)?.toDouble() ?? 0.0,
    );
  }

  RevenueByTypeEntity toEntity() => RevenueByTypeEntity(
        typeName: typeName,
        amount: amount,
        percentage: percentage,
        batchCount: batchCount,
        avgPerBatch: avgPerBatch,
        trend: trend,
      );
}

class RevenueByBranchModel {
  final String branchName;
  final double amount;

  const RevenueByBranchModel({required this.branchName, required this.amount});

  factory RevenueByBranchModel.fromJson(Map<String, dynamic> json) {
    return RevenueByBranchModel(
      branchName: json['branch_name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  RevenueByBranchEntity toEntity() =>
      RevenueByBranchEntity(branchName: branchName, amount: amount);
}

class RevenueAnalysisModel {
  final List<RevenueTrendPointModel> trend;
  final List<RevenueByTypeModel> byType;
  final List<RevenueByBranchModel> byBranch;

  const RevenueAnalysisModel({
    required this.trend,
    required this.byType,
    required this.byBranch,
  });

  factory RevenueAnalysisModel.fromJson(Map<String, dynamic> json) {
    final trendList = json['trend'] is List ? json['trend'] as List : [];
    final byTypeList = json['by_type'] is List ? json['by_type'] as List : [];
    final byBranchList = json['by_branch'] is List ? json['by_branch'] as List : [];

    return RevenueAnalysisModel(
      trend: trendList
          .map((e) => RevenueTrendPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      byType: byTypeList
          .map((e) => RevenueByTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      byBranch: byBranchList
          .map((e) => RevenueByBranchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  RevenueAnalysisEntity toEntity() => RevenueAnalysisEntity(
        trend: trend.map((e) => e.toEntity()).toList(),
        byType: byType.map((e) => e.toEntity()).toList(),
        byBranch: byBranch.map((e) => e.toEntity()).toList(),
      );
}

class CostTrendPointModel {
  final String month;
  final double facilitator;
  final double commission;
  final double operational;
  final double marketing;
  final double investment;
  final double total;

  const CostTrendPointModel({
    required this.month,
    required this.facilitator,
    required this.commission,
    required this.operational,
    required this.marketing,
    required this.investment,
    required this.total,
  });

  factory CostTrendPointModel.fromJson(Map<String, dynamic> json) {
    return CostTrendPointModel(
      month: json['month']?.toString() ?? '',
      facilitator: (json['facilitator'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      operational: (json['operational'] as num?)?.toDouble() ?? 0.0,
      marketing: (json['marketing'] as num?)?.toDouble() ?? 0.0,
      investment: (json['investment'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CostTrendPoint toEntity() => CostTrendPoint(
        month: month,
        facilitator: facilitator,
        commission: commission,
        operational: operational,
        marketing: marketing,
        investment: investment,
        total: total,
      );
}

class CostByCategoryModel {
  final String category;
  final double amount;
  final double percentage;
  final double vsLastMonth;
  final double trend;

  const CostByCategoryModel({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.vsLastMonth,
    required this.trend,
  });

  factory CostByCategoryModel.fromJson(Map<String, dynamic> json) {
    return CostByCategoryModel(
      category: json['category']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      vsLastMonth: (json['vs_last_month'] as num?)?.toDouble() ?? 0.0,
      trend: (json['trend'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CostByCategory toEntity() => CostByCategory(
        category: category,
        amount: amount,
        percentage: percentage,
        vsLastMonth: vsLastMonth,
        trend: trend,
      );
}

class CostAnalysisModel {
  final List<CostTrendPointModel> trend;
  final List<CostByCategoryModel> byCategory;

  const CostAnalysisModel({required this.trend, required this.byCategory});

  factory CostAnalysisModel.fromJson(Map<String, dynamic> json) {
    final trendList = json['trend'] is List ? json['trend'] as List : [];
    final byCategoryList =
        json['by_category'] is List ? json['by_category'] as List : [];

    return CostAnalysisModel(
      trend: trendList
          .map((e) => CostTrendPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      byCategory: byCategoryList
          .map((e) => CostByCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  CostAnalysisEntity toEntity() => CostAnalysisEntity(
        trend: trend.map((e) => e.toEntity()).toList(),
        byCategory: byCategory.map((e) => e.toEntity()).toList(),
      );
}

class BatchProfitModel {
  final String batchCode;
  final String courseName;
  final double revenue;
  final double expenditure;
  final double commission;
  final double profit;
  final double marginPercent;

  const BatchProfitModel({
    required this.batchCode,
    required this.courseName,
    required this.revenue,
    required this.expenditure,
    required this.commission,
    required this.profit,
    required this.marginPercent,
  });

  factory BatchProfitModel.fromJson(Map<String, dynamic> json) {
    return BatchProfitModel(
      batchCode: json['batch_code']?.toString() ?? '',
      courseName: json['course_name']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      expenditure: (json['expenditure'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      marginPercent: (json['margin_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  BatchProfitEntity toEntity() => BatchProfitEntity(
        batchCode: batchCode,
        courseName: courseName,
        revenue: revenue,
        expenditure: expenditure,
        commission: commission,
        profit: profit,
        marginPercent: marginPercent,
      );
}

class HistogramBucketModel {
  final String rangeLabel;
  final int count;

  const HistogramBucketModel({required this.rangeLabel, required this.count});

  factory HistogramBucketModel.fromJson(Map<String, dynamic> json) {
    return HistogramBucketModel(
      rangeLabel: json['range_label']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  HistogramBucket toEntity() =>
      HistogramBucket(rangeLabel: rangeLabel, count: count);
}

class BatchProfitAnalysisModel {
  final List<BatchProfitModel> topBatches;
  final List<BatchProfitModel> bottomBatches;
  final List<HistogramBucketModel> histogram;

  const BatchProfitAnalysisModel({
    required this.topBatches,
    required this.bottomBatches,
    required this.histogram,
  });

  BatchProfitAnalysisEntity toEntity() => BatchProfitAnalysisEntity(
        topBatches: topBatches.map((e) => e.toEntity()).toList(),
        bottomBatches: bottomBatches.map((e) => e.toEntity()).toList(),
        histogram: histogram.map((e) => e.toEntity()).toList(),
      );
}

class CashForecastPointModel {
  final String month;
  final double projectedCash;
  final double projectedInflow;
  final double projectedOutflow;

  const CashForecastPointModel({
    required this.month,
    required this.projectedCash,
    required this.projectedInflow,
    required this.projectedOutflow,
  });

  factory CashForecastPointModel.fromJson(Map<String, dynamic> json) {
    return CashForecastPointModel(
      month: json['month']?.toString() ?? '',
      projectedCash: (json['projected_cash'] as num?)?.toDouble() ?? 0.0,
      projectedInflow: (json['projected_inflow'] as num?)?.toDouble() ?? 0.0,
      projectedOutflow: (json['projected_outflow'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CashForecastPoint toEntity() => CashForecastPoint(
        month: month,
        projectedCash: projectedCash,
        projectedInflow: projectedInflow,
        projectedOutflow: projectedOutflow,
      );
}

class CashEventModel {
  final String date;
  final String type;
  final String description;
  final double amount;
  final String status;

  const CashEventModel({
    required this.date,
    required this.type,
    required this.description,
    required this.amount,
    required this.status,
  });

  factory CashEventModel.fromJson(Map<String, dynamic> json) {
    return CashEventModel(
      date: json['date']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? '',
    );
  }

  CashEventEntity toEntity() => CashEventEntity(
        date: date,
        type: type,
        description: description,
        amount: amount,
        status: status,
      );
}

class CashForecastModel {
  final List<CashForecastPointModel> projection;
  final List<CashEventModel> upcomingEvents;

  const CashForecastModel({
    required this.projection,
    required this.upcomingEvents,
  });

  factory CashForecastModel.fromJson(Map<String, dynamic> json) {
    final projList = json['projection'] is List ? json['projection'] as List : [];
    final eventList =
        json['upcoming_events'] is List ? json['upcoming_events'] as List : [];

    return CashForecastModel(
      projection: projList
          .map((e) => CashForecastPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      upcomingEvents: eventList
          .map((e) => CashEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  CashForecastEntity toEntity() => CashForecastEntity(
        projection: projection.map((e) => e.toEntity()).toList(),
        upcomingEvents: upcomingEvents.map((e) => e.toEntity()).toList(),
      );
}

class FinanceAlertModel {
  final String type;
  final String message;

  const FinanceAlertModel({required this.type, required this.message});

  factory FinanceAlertModel.fromJson(Map<String, dynamic> json) {
    return FinanceAlertModel(
      type: json['type']?.toString() ?? 'info',
      message: json['message']?.toString() ?? '',
    );
  }

  FinanceAlertEntity toEntity() =>
      FinanceAlertEntity(type: type, message: message);
}
