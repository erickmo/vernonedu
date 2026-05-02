import 'package:dio/dio.dart';
import '../models/finance_analysis_model.dart';

abstract class FinanceAnalysisRemoteDataSource {
  Future<FinancialRatiosModel> fetchRatios({
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

  Future<BatchProfitModel> fetchBatchProfit({
    String period,
    String? branchId,
    String sort,
    int limit,
  });

  Future<CashForecastModel> fetchCashForecast({
    int months,
    String? branchId,
  });

  Future<List<FinancialAlertModel>> fetchAlerts();
  Future<List<FinancialSuggestionModel>> fetchSuggestions();
}

class FinanceAnalysisRemoteDataSourceImpl
    implements FinanceAnalysisRemoteDataSource {
  final Dio _dio;
  const FinanceAnalysisRemoteDataSourceImpl(this._dio);

  Map<String, dynamic> _objJson(dynamic raw) {
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  List<dynamic> _listJson(dynamic raw) {
    if (raw is Map && raw['data'] is List) return List<dynamic>.from(raw['data'] as List);
    if (raw is List) return List<dynamic>.from(raw);
    return <dynamic>[];
  }

  @override
  Future<FinancialRatiosModel> fetchRatios({
    String period = 'monthly',
    String? branchId,
    String comparison = 'prev_month',
  }) async {
    final params = <String, dynamic>{'period': period, 'comparison': comparison};
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    final res = await _dio.get('/finance/analysis/ratios', queryParameters: params);
    return FinancialRatiosModel.fromJson(_objJson(res.data));
  }

  @override
  Future<RevenueAnalysisModel> fetchRevenue({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'month',
  }) async {
    final params = <String, dynamic>{'period': period, 'group_by': groupBy};
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    final res = await _dio.get('/finance/analysis/revenue', queryParameters: params);
    return RevenueAnalysisModel.fromJson(_objJson(res.data));
  }

  @override
  Future<CostAnalysisModel> fetchCosts({
    String period = 'monthly',
    String? branchId,
    String groupBy = 'category',
  }) async {
    final params = <String, dynamic>{'period': period, 'group_by': groupBy};
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    final res = await _dio.get('/finance/analysis/costs', queryParameters: params);
    return CostAnalysisModel.fromJson(_objJson(res.data));
  }

  @override
  Future<BatchProfitModel> fetchBatchProfit({
    String period = 'monthly',
    String? branchId,
    String sort = 'top',
    int limit = 10,
  }) async {
    final params = <String, dynamic>{'period': period, 'sort': sort, 'limit': limit};
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    final res = await _dio.get('/finance/analysis/batch-profit', queryParameters: params);
    return BatchProfitModel.fromJson(_objJson(res.data));
  }

  @override
  Future<CashForecastModel> fetchCashForecast({
    int months = 3,
    String? branchId,
  }) async {
    final params = <String, dynamic>{'months': months};
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    final res = await _dio.get('/finance/analysis/cash-forecast', queryParameters: params);
    return CashForecastModel.fromJson(_objJson(res.data));
  }

  @override
  Future<List<FinancialAlertModel>> fetchAlerts() async {
    final res = await _dio.get('/finance/analysis/alerts');
    return _listJson(res.data)
        .map((e) => FinancialAlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FinancialSuggestionModel>> fetchSuggestions() async {
    final res = await _dio.get('/finance/analysis/suggestions');
    return _listJson(res.data)
        .map((e) => FinancialSuggestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
