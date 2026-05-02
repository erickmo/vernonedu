import '../../domain/entities/finance_analysis_entity.dart';

double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
int _toInt(dynamic v) => (v as num?)?.toInt() ?? 0;
String _toStr(dynamic v) => v?.toString() ?? '';

// --- Financial Ratios -------------------------------------------------------

class RatioMetricModel {
  final double current;
  final double previous;
  final double change;
  final double changePct;
  final String trend;

  const RatioMetricModel({
    required this.current,
    required this.previous,
    required this.change,
    required this.changePct,
    required this.trend,
  });

  factory RatioMetricModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RatioMetricModel(
        current: 0,
        previous: 0,
        change: 0,
        changePct: 0,
        trend: 'flat',
      );
    }
    return RatioMetricModel(
      current: _toDouble(json['current']),
      previous: _toDouble(json['previous']),
      change: _toDouble(json['change']),
      changePct: _toDouble(json['change_pct']),
      trend: _toStr(json['trend']).isEmpty ? 'flat' : _toStr(json['trend']),
    );
  }

  RatioMetric toEntity() => RatioMetric(
        current: current,
        previous: previous,
        change: change,
        changePct: changePct,
        trend: trend,
      );
}

class FinancialRatiosModel {
  final RatioMetricModel profitMargin;
  final RatioMetricModel expenseRatio;
  final RatioMetricModel revenuePerStudent;
  final RatioMetricModel costPerStudent;
  final RatioMetricModel avgBatchProfitability;
  final RatioMetricModel collectionRate;
  final RatioMetricModel daysSalesOutstanding;
  final RatioMetricModel revenueGrowthRate;

  const FinancialRatiosModel({
    required this.profitMargin,
    required this.expenseRatio,
    required this.revenuePerStudent,
    required this.costPerStudent,
    required this.avgBatchProfitability,
    required this.collectionRate,
    required this.daysSalesOutstanding,
    required this.revenueGrowthRate,
  });

  factory FinancialRatiosModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? sub(String k) =>
        json[k] is Map<String, dynamic> ? json[k] as Map<String, dynamic> : null;
    return FinancialRatiosModel(
      profitMargin: RatioMetricModel.fromJson(sub('profit_margin')),
      expenseRatio: RatioMetricModel.fromJson(sub('expense_ratio')),
      revenuePerStudent: RatioMetricModel.fromJson(sub('revenue_per_student')),
      costPerStudent: RatioMetricModel.fromJson(sub('cost_per_student')),
      avgBatchProfitability:
          RatioMetricModel.fromJson(sub('avg_batch_profitability')),
      collectionRate: RatioMetricModel.fromJson(sub('collection_rate')),
      daysSalesOutstanding:
          RatioMetricModel.fromJson(sub('days_sales_outstanding')),
      revenueGrowthRate:
          RatioMetricModel.fromJson(sub('revenue_growth_rate')),
    );
  }

  FinancialRatiosEntity toEntity() => FinancialRatiosEntity(
        profitMargin: profitMargin.toEntity(),
        expenseRatio: expenseRatio.toEntity(),
        revenuePerStudent: revenuePerStudent.toEntity(),
        costPerStudent: costPerStudent.toEntity(),
        avgBatchProfitability: avgBatchProfitability.toEntity(),
        collectionRate: collectionRate.toEntity(),
        daysSalesOutstanding: daysSalesOutstanding.toEntity(),
        revenueGrowthRate: revenueGrowthRate.toEntity(),
      );
}

// --- Revenue ----------------------------------------------------------------

class MonthlyRevenuePointModel {
  final String month;
  final double total;
  final double regular;
  final double career;
  final double inhouse;
  final double collab;
  final double cert;

  const MonthlyRevenuePointModel({
    required this.month,
    required this.total,
    required this.regular,
    required this.career,
    required this.inhouse,
    required this.collab,
    required this.cert,
  });

  factory MonthlyRevenuePointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenuePointModel(
      month: _toStr(json['month']),
      total: _toDouble(json['total']),
      regular: _toDouble(json['regular']),
      career: _toDouble(json['career']),
      inhouse: _toDouble(json['inhouse']),
      collab: _toDouble(json['collab']),
      cert: _toDouble(json['cert']),
    );
  }

  MonthlyRevenuePoint toEntity() => MonthlyRevenuePoint(
        month: month,
        total: total,
        regular: regular,
        career: career,
        inhouse: inhouse,
        collab: collab,
        cert: cert,
      );
}

class RevenueByGroupModel {
  final String groupKey;
  final double revenue;
  final double pctOfTotal;
  final int batchCount;
  final double avgPerBatch;
  final String trend;

  const RevenueByGroupModel({
    required this.groupKey,
    required this.revenue,
    required this.pctOfTotal,
    required this.batchCount,
    required this.avgPerBatch,
    required this.trend,
  });

  factory RevenueByGroupModel.fromJson(Map<String, dynamic> json) {
    return RevenueByGroupModel(
      groupKey: _toStr(json['group_key']),
      revenue: _toDouble(json['revenue']),
      pctOfTotal: _toDouble(json['pct_of_total']),
      batchCount: _toInt(json['batch_count']),
      avgPerBatch: _toDouble(json['avg_per_batch']),
      trend: _toStr(json['trend']),
    );
  }

  RevenueByGroup toEntity() => RevenueByGroup(
        groupKey: groupKey,
        revenue: revenue,
        pctOfTotal: pctOfTotal,
        batchCount: batchCount,
        avgPerBatch: avgPerBatch,
        trend: trend,
      );
}

class RevenueAnalysisModel {
  final List<MonthlyRevenuePointModel> monthlyTrend;
  final List<RevenueByGroupModel> byGroup;
  final double totalRevenue;
  final String groupBy;

  const RevenueAnalysisModel({
    required this.monthlyTrend,
    required this.byGroup,
    required this.totalRevenue,
    required this.groupBy,
  });

  factory RevenueAnalysisModel.fromJson(Map<String, dynamic> json) {
    final mt = json['monthly_trend'];
    final bg = json['by_group'];
    return RevenueAnalysisModel(
      monthlyTrend: (mt is List)
          ? mt
              .map((e) =>
                  MonthlyRevenuePointModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : <MonthlyRevenuePointModel>[],
      byGroup: (bg is List)
          ? bg
              .map((e) =>
                  RevenueByGroupModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : <RevenueByGroupModel>[],
      totalRevenue: _toDouble(json['total_revenue']),
      groupBy: _toStr(json['group_by']),
    );
  }

  RevenueAnalysisEntity toEntity() => RevenueAnalysisEntity(
        monthlyTrend: monthlyTrend.map((e) => e.toEntity()).toList(),
        byGroup: byGroup.map((e) => e.toEntity()).toList(),
        totalRevenue: totalRevenue,
        groupBy: groupBy,
      );
}

// --- Cost -------------------------------------------------------------------

class MonthlyCostPointModel {
  final String month;
  final double total;
  final double facilitator;
  final double commission;
  final double operational;
  final double marketing;
  final double other;

  const MonthlyCostPointModel({
    required this.month,
    required this.total,
    required this.facilitator,
    required this.commission,
    required this.operational,
    required this.marketing,
    required this.other,
  });

  factory MonthlyCostPointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyCostPointModel(
      month: _toStr(json['month']),
      total: _toDouble(json['total']),
      facilitator: _toDouble(json['facilitator']),
      commission: _toDouble(json['commission']),
      operational: _toDouble(json['operational']),
      marketing: _toDouble(json['marketing']),
      other: _toDouble(json['other']),
    );
  }

  MonthlyCostPoint toEntity() => MonthlyCostPoint(
        month: month,
        total: total,
        facilitator: facilitator,
        commission: commission,
        operational: operational,
        marketing: marketing,
        other: other,
      );
}

class CostByCategoryModel {
  final String category;
  final double amount;
  final double pctOfTotal;
  final double vsPrevious;
  final String trend;

  const CostByCategoryModel({
    required this.category,
    required this.amount,
    required this.pctOfTotal,
    required this.vsPrevious,
    required this.trend,
  });

  factory CostByCategoryModel.fromJson(Map<String, dynamic> json) {
    return CostByCategoryModel(
      category: _toStr(json['category']),
      amount: _toDouble(json['amount']),
      pctOfTotal: _toDouble(json['pct_of_total']),
      vsPrevious: _toDouble(json['vs_previous']),
      trend: _toStr(json['trend']),
    );
  }

  CostByCategory toEntity() => CostByCategory(
        category: category,
        amount: amount,
        pctOfTotal: pctOfTotal,
        vsPrevious: vsPrevious,
        trend: trend,
      );
}

class CostAnalysisModel {
  final List<MonthlyCostPointModel> monthlyTrend;
  final List<CostByCategoryModel> byCategory;
  final double totalCost;

  const CostAnalysisModel({
    required this.monthlyTrend,
    required this.byCategory,
    required this.totalCost,
  });

  factory CostAnalysisModel.fromJson(Map<String, dynamic> json) {
    final mt = json['monthly_trend'];
    final bc = json['by_category'];
    return CostAnalysisModel(
      monthlyTrend: (mt is List)
          ? mt
              .map((e) =>
                  MonthlyCostPointModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : <MonthlyCostPointModel>[],
      byCategory: (bc is List)
          ? bc
              .map((e) =>
                  CostByCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : <CostByCategoryModel>[],
      totalCost: _toDouble(json['total_cost']),
    );
  }

  CostAnalysisEntity toEntity() => CostAnalysisEntity(
        monthlyTrend: monthlyTrend.map((e) => e.toEntity()).toList(),
        byCategory: byCategory.map((e) => e.toEntity()).toList(),
        totalCost: totalCost,
      );
}

// --- Batch Profit -----------------------------------------------------------

class BatchProfitItemModel {
  final String batchId;
  final String batchCode;
  final String courseName;
  final double revenue;
  final double expense;
  final double commission;
  final double profit;
  final double marginPct;

  const BatchProfitItemModel({
    required this.batchId,
    required this.batchCode,
    required this.courseName,
    required this.revenue,
    required this.expense,
    required this.commission,
    required this.profit,
    required this.marginPct,
  });

  factory BatchProfitItemModel.fromJson(Map<String, dynamic> json) {
    return BatchProfitItemModel(
      batchId: _toStr(json['batch_id']),
      batchCode: _toStr(json['batch_code']),
      courseName: _toStr(json['course_name']),
      revenue: _toDouble(json['revenue']),
      expense: _toDouble(json['expense']),
      commission: _toDouble(json['commission']),
      profit: _toDouble(json['profit']),
      marginPct: _toDouble(json['margin_pct']),
    );
  }

  BatchProfitItem toEntity() => BatchProfitItem(
        batchId: batchId,
        batchCode: batchCode,
        courseName: courseName,
        revenue: revenue,
        expense: expense,
        commission: commission,
        profit: profit,
        marginPct: marginPct,
      );
}

class BatchProfitModel {
  final List<BatchProfitItemModel> items;
  final double avgMargin;
  final String sort;

  const BatchProfitModel({
    required this.items,
    required this.avgMargin,
    required this.sort,
  });

  factory BatchProfitModel.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return BatchProfitModel(
      items: (raw is List)
          ? raw
              .map((e) =>
                  BatchProfitItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : <BatchProfitItemModel>[],
      avgMargin: _toDouble(json['avg_margin']),
      sort: _toStr(json['sort']),
    );
  }

  BatchProfitEntity toEntity() => BatchProfitEntity(
        items: items.map((e) => e.toEntity()).toList(),
        avgMargin: avgMargin,
        sort: sort,
      );
}

// --- Cash Forecast ----------------------------------------------------------

class CashForecastMonthModel {
  final String month;
  final double openingCash;
  final double inflow;
  final double outflow;
  final double closingCash;

  const CashForecastMonthModel({
    required this.month,
    required this.openingCash,
    required this.inflow,
    required this.outflow,
    required this.closingCash,
  });

  factory CashForecastMonthModel.fromJson(Map<String, dynamic> json) {
    return CashForecastMonthModel(
      month: _toStr(json['month']),
      openingCash: _toDouble(json['opening_cash']),
      inflow: _toDouble(json['inflow']),
      outflow: _toDouble(json['outflow']),
      closingCash: _toDouble(json['closing_cash']),
    );
  }

  CashForecastMonth toEntity() => CashForecastMonth(
        month: month,
        openingCash: openingCash,
        inflow: inflow,
        outflow: outflow,
        closingCash: closingCash,
      );
}

class CashEventModel {
  final String date;
  final String eventType;
  final String description;
  final double amount;
  final String status;

  const CashEventModel({
    required this.date,
    required this.eventType,
    required this.description,
    required this.amount,
    required this.status,
  });

  factory CashEventModel.fromJson(Map<String, dynamic> json) {
    return CashEventModel(
      date: _toStr(json['date']),
      eventType: _toStr(json['event_type']),
      description: _toStr(json['description']),
      amount: _toDouble(json['amount']),
      status: _toStr(json['status']),
    );
  }

  CashEvent toEntity() => CashEvent(
        date: date,
        eventType: eventType,
        description: description,
        amount: amount,
        status: status,
      );
}

class CashForecastModel {
  final double currentCash;
  final List<CashForecastMonthModel> months;
  final List<CashEventModel> upcomingEvents;

  const CashForecastModel({
    required this.currentCash,
    required this.months,
    required this.upcomingEvents,
  });

  factory CashForecastModel.fromJson(Map<String, dynamic> json) {
    final m = json['months'];
    final ev = json['upcoming_events'];
    return CashForecastModel(
      currentCash: _toDouble(json['current_cash']),
      months: (m is List)
          ? m
              .map((e) =>
                  CashForecastMonthModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : <CashForecastMonthModel>[],
      upcomingEvents: (ev is List)
          ? ev
              .map((e) => CashEventModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : <CashEventModel>[],
    );
  }

  CashForecastEntity toEntity() => CashForecastEntity(
        currentCash: currentCash,
        months: months.map((e) => e.toEntity()).toList(),
        upcomingEvents: upcomingEvents.map((e) => e.toEntity()).toList(),
      );
}

// --- Alerts -----------------------------------------------------------------

class FinancialAlertModel {
  final String level;
  final String code;
  final String message;
  final int count;
  final double amount;

  const FinancialAlertModel({
    required this.level,
    required this.code,
    required this.message,
    this.count = 0,
    this.amount = 0,
  });

  factory FinancialAlertModel.fromJson(Map<String, dynamic> json) {
    return FinancialAlertModel(
      level: _toStr(json['level']).isEmpty ? 'info' : _toStr(json['level']),
      code: _toStr(json['code']),
      message: _toStr(json['message']),
      count: _toInt(json['count']),
      amount: _toDouble(json['amount']),
    );
  }

  FinancialAlert toEntity() => FinancialAlert(
        level: level,
        code: code,
        message: message,
        count: count,
        amount: amount,
      );
}

// --- Suggestions ------------------------------------------------------------

class FinancialSuggestionModel {
  final String icon;
  final String message;
  final double amount;
  final String detail;

  const FinancialSuggestionModel({
    required this.icon,
    required this.message,
    this.amount = 0,
    this.detail = '',
  });

  factory FinancialSuggestionModel.fromJson(Map<String, dynamic> json) {
    return FinancialSuggestionModel(
      icon: _toStr(json['icon']),
      message: _toStr(json['message']),
      amount: _toDouble(json['amount']),
      detail: _toStr(json['detail']),
    );
  }

  FinancialSuggestion toEntity() => FinancialSuggestion(
        icon: icon,
        message: message,
        amount: amount,
        detail: detail,
      );
}
