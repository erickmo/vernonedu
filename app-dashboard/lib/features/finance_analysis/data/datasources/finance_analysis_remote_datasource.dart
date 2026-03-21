import 'package:dio/dio.dart';
import '../models/finance_analysis_model.dart';

abstract class FinanceAnalysisRemoteDataSource {
  Future<FinancialRatioModel> fetchRatios({
    String period,
    String? branchId,
    String comparison,
  });

  Future<RevenueAnalysisModel> fetchRevenue({
    String period,
    String? branchId,
    String groupBy,
  });

  Future<CostAnalysisModel> fetchCosts({
    String period,
    String? branchId,
    String groupBy,
  });

  Future<BatchProfitAnalysisModel> fetchBatchProfit({
    String period,
    String? branchId,
    int limit,
  });

  Future<CashForecastModel> fetchCashForecast({
    int months,
    String? branchId,
  });

  Future<List<FinanceAlertModel>> fetchAlerts();
  Future<List<FinanceAlertModel>> fetchSuggestions();
}

class FinanceAnalysisRemoteDataSourceImpl
    implements FinanceAnalysisRemoteDataSource {
  final Dio _dio;
  const FinanceAnalysisRemoteDataSourceImpl(this._dio);

  @override
  Future<FinancialRatioModel> fetchRatios({
    String period = 'monthly',
    String? branchId,
    String comparison = 'vs_last_month',
  }) async {
    final params = <String, dynamic>{
      'period': period,
      'comparison': comparison,
    };
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;

    final res = await _dio.get(
      '/finance/analysis/ratios',
      queryParameters: params,
    );
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return FinancialRatioModel.fromJson(json);
  }

  @override
  Future<RevenueAnalysisModel> fetchRevenue({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'month',
  }) async {
    final params = <String, dynamic>{
      'period': period,
      'group_by': groupBy,
    };
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;

    final res = await _dio.get(
      '/finance/analysis/revenue',
      queryParameters: params,
    );
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return RevenueAnalysisModel.fromJson(json);
  }

  @override
  Future<CostAnalysisModel> fetchCosts({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'month',
  }) async {
    final params = <String, dynamic>{
      'period': period,
      'group_by': groupBy,
    };
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;

    final res = await _dio.get(
      '/finance/analysis/costs',
      queryParameters: params,
    );
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return CostAnalysisModel.fromJson(json);
  }

  @override
  Future<BatchProfitAnalysisModel> fetchBatchProfit({
    String period = 'monthly',
    String? branchId,
    int limit = 10,
  }) async {
    final params = <String, dynamic>{
      'period': period,
      'limit': limit,
    };
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;

    final topParams = Map<String, dynamic>.from(params)..['sort'] = 'top';
    final bottomParams = Map<String, dynamic>.from(params)..['sort'] = 'bottom';

    final results = await Future.wait([
      _dio.get('/finance/analysis/batch-profit', queryParameters: topParams),
      _dio.get('/finance/analysis/batch-profit', queryParameters: bottomParams),
    ]);

    List<BatchProfitModel> parseList(dynamic res) {
      final raw = (res as Response).data;
      List list;
      if (raw is Map && raw['data'] != null) {
        final inner = raw['data'];
        list = inner is List ? inner : [];
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }
      return list
          .map((e) => BatchProfitModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Parse histogram from top response if available
    final topRaw = results[0].data;
    List<HistogramBucketModel> histogram = [];
    if (topRaw is Map && topRaw['histogram'] != null) {
      final histList = topRaw['histogram'] as List;
      histogram = histList
          .map((e) =>
              HistogramBucketModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return BatchProfitAnalysisModel(
      topBatches: parseList(results[0]),
      bottomBatches: parseList(results[1]),
      histogram: histogram,
    );
  }

  @override
  Future<CashForecastModel> fetchCashForecast({
    int months = 3,
    String? branchId,
  }) async {
    final params = <String, dynamic>{'months': months};
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;

    final res = await _dio.get(
      '/finance/analysis/cash-forecast',
      queryParameters: params,
    );
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return CashForecastModel.fromJson(json);
  }

  @override
  Future<List<FinanceAlertModel>> fetchAlerts() async {
    final res = await _dio.get('/finance/analysis/alerts');
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => FinanceAlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FinanceAlertModel>> fetchSuggestions() async {
    final res = await _dio.get('/finance/analysis/suggestions');
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => FinanceAlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
