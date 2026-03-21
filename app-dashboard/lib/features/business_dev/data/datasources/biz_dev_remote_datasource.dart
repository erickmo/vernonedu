import 'package:dio/dio.dart';

import '../models/partner_model.dart';
import '../models/branch_model.dart';
import '../models/okr_model.dart';
import '../models/investment_model.dart';
import '../models/delegation_model.dart';

abstract class BizDevRemoteDataSource {
  Future<Map<String, dynamic>> getPartners({
    int offset = 0,
    int limit = 20,
    String status = '',
  });

  Future<Map<String, dynamic>> getBranches({
    int offset = 0,
    int limit = 20,
  });

  Future<List<OkrObjectiveModel>> getOkrObjectives({String level = ''});

  Future<Map<String, dynamic>> getInvestments({
    int offset = 0,
    int limit = 20,
    String status = '',
  });

  Future<Map<String, dynamic>> getDelegations({
    int offset = 0,
    int limit = 20,
    String status = '',
  });
}

class BizDevRemoteDataSourceImpl implements BizDevRemoteDataSource {
  final Dio _dio;

  const BizDevRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getPartners({
    int offset = 0,
    int limit = 20,
    String status = '',
  }) async {
    final params = <String, dynamic>{'offset': offset, 'limit': limit};
    if (status.isNotEmpty) params['status'] = status;
    final res = await _dio.get('/partners', queryParameters: params);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getBranches({
    int offset = 0,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '/branches',
      queryParameters: {'offset': offset, 'limit': limit},
    );
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  @override
  Future<List<OkrObjectiveModel>> getOkrObjectives({String level = ''}) async {
    final params = <String, dynamic>{};
    if (level.isNotEmpty && level != 'all') params['level'] = level;
    final res = await _dio.get('/okr', queryParameters: params);
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => OkrObjectiveModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getInvestments({
    int offset = 0,
    int limit = 20,
    String status = '',
  }) async {
    final params = <String, dynamic>{'offset': offset, 'limit': limit};
    if (status.isNotEmpty) params['status'] = status;
    final res = await _dio.get('/investments', queryParameters: params);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getDelegations({
    int offset = 0,
    int limit = 20,
    String status = '',
  }) async {
    final params = <String, dynamic>{'offset': offset, 'limit': limit};
    if (status.isNotEmpty) params['status'] = status;
    final res = await _dio.get('/delegations', queryParameters: params);
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  }
}
