import 'package:dio/dio.dart';
import '../models/talentpool_model.dart';
import '../models/job_opening_model.dart';
import '../models/partner_company_model.dart';

// Kontrak abstract datasource untuk TalentPool
abstract class TalentPoolRemoteDataSource {
  Future<List<TalentPoolModel>> getTalentPool({
    int offset = 0,
    int limit = 20,
    String status = '',
    String masterCourseId = '',
    String participantId = '',
  });
  Future<TalentPoolModel> getTalentPoolById(String id);

  // PUT /api/v1/talentpool/{id}/status
  // body: {"status": "placed"|"inactive", "placement": {...}}
  Future<void> updateStatus(String id, String status, Map<String, dynamic>? placement);

  Future<List<JobOpeningModel>> getJobOpenings({int offset = 0, int limit = 50});
  Future<List<PartnerCompanyModel>> getPartnerCompanies({int offset = 0, int limit = 50});
}

// Implementasi datasource menggunakan Dio — endpoint: /api/v1/talentpool
class TalentPoolRemoteDataSourceImpl implements TalentPoolRemoteDataSource {
  final Dio _dio;
  const TalentPoolRemoteDataSourceImpl(this._dio);

  // GET /api/v1/talentpool
  // Query params: offset, limit, status (opsional), master_course_id (opsional)
  @override
  Future<List<TalentPoolModel>> getTalentPool({
    int offset = 0,
    int limit = 20,
    String status = '',
    String masterCourseId = '',
    String participantId = '',
  }) async {
    final params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
    };
    if (status.isNotEmpty) params['status'] = status;
    if (masterCourseId.isNotEmpty) params['master_course_id'] = masterCourseId;
    if (participantId.isNotEmpty) params['participant_id'] = participantId;

    final res = await _dio.get('/talentpool', queryParameters: params);
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => TalentPoolModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/v1/talentpool/{id}
  @override
  Future<TalentPoolModel> getTalentPoolById(String id) async {
    final res = await _dio.get('/talentpool/$id');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return TalentPoolModel.fromJson(json);
  }

  @override
  Future<List<JobOpeningModel>> getJobOpenings({int offset = 0, int limit = 50}) async {
    final res = await _dio.get('/talentpool/jobs',
        queryParameters: {'offset': offset, 'limit': limit});
    final raw = (res.data is Map && res.data['data'] != null)
        ? res.data['data']
        : res.data is List
            ? res.data
            : <dynamic>[];
    return (raw as List)
        .map((e) => JobOpeningModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PartnerCompanyModel>> getPartnerCompanies(
      {int offset = 0, int limit = 50}) async {
    final res = await _dio.get('/talentpool/companies',
        queryParameters: {'offset': offset, 'limit': limit});
    final raw = (res.data is Map && res.data['data'] != null)
        ? res.data['data']
        : res.data is List
            ? res.data
            : <dynamic>[];
    return (raw as List)
        .map((e) => PartnerCompanyModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // PUT /api/v1/talentpool/{id}/status
  @override
  Future<void> updateStatus(String id, String status, Map<String, dynamic>? placement) async {
    final body = <String, dynamic>{'status': status};
    if (placement != null && placement.isNotEmpty) {
      body['placement'] = placement;
    }
    await _dio.put('/talentpool/$id/status', data: body);
  }
}
