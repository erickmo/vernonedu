import 'package:dio/dio.dart';
import '../models/lead_model.dart';
import '../models/crm_log_model.dart';

abstract class LeadRemoteDataSource {
  Future<List<LeadModel>> getLeads({int offset = 0, int limit = 50, String? status});
  Future<LeadModel> getLeadById(String id);
  Future<LeadModel> createLead(Map<String, dynamic> data);
  Future<LeadModel> updateLead(String id, Map<String, dynamic> data);
  Future<void> deleteLead(String id);
  Future<List<CrmLogModel>> getCrmLogs(String leadId);
  Future<void> addCrmLog(String leadId, Map<String, dynamic> data);
  Future<void> convertToStudent(String leadId);
}

class LeadRemoteDataSourceImpl implements LeadRemoteDataSource {
  final Dio _dio;
  const LeadRemoteDataSourceImpl(this._dio);

  @override
  Future<List<LeadModel>> getLeads({
    int offset = 0,
    int limit = 50,
    String? status,
  }) async {
    final params = <String, dynamic>{'offset': offset, 'limit': limit};
    if (status != null && status.isNotEmpty) params['status'] = status;

    final res = await _dio.get('/leads', queryParameters: params);
    final raw = res.data;

    // Response: { "data": { "data": [...], "total": N, ... } }
    List list;
    if (raw is Map && raw['data'] != null) {
      final inner = raw['data'];
      if (inner is Map && inner['data'] != null) {
        list = inner['data'] as List;
      } else if (inner is List) {
        list = inner;
      } else {
        list = [];
      }
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }

    return list.map((e) => LeadModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<LeadModel> getLeadById(String id) async {
    final res = await _dio.get('/leads/$id');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return LeadModel.fromJson(json);
  }

  @override
  Future<LeadModel> createLead(Map<String, dynamic> data) async {
    final res = await _dio.post('/leads', data: data);
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return LeadModel.fromJson(json);
  }

  @override
  Future<LeadModel> updateLead(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/leads/$id', data: data);
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return LeadModel.fromJson(json);
  }

  @override
  Future<void> deleteLead(String id) async {
    await _dio.delete('/leads/$id');
  }

  @override
  Future<List<CrmLogModel>> getCrmLogs(String leadId) async {
    final res = await _dio.get('/leads/$leadId/crm-logs');
    final raw = res.data;
    List list;
    if (raw is Map && raw['data'] != null) {
      final inner = raw['data'];
      list = inner is List
          ? inner
          : (inner is Map && inner['data'] != null ? inner['data'] as List : []);
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }
    return list
        .map((e) => CrmLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addCrmLog(String leadId, Map<String, dynamic> data) async {
    await _dio.post('/leads/$leadId/crm-logs', data: data);
  }

  @override
  Future<void> convertToStudent(String leadId) async {
    await _dio.post('/leads/$leadId/convert');
  }
}
