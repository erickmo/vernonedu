import 'package:dio/dio.dart';

import '../models/certificate_model.dart';
import '../models/certificate_template_model.dart';

abstract class CertificateRemoteDataSource {
  Future<List<CertificateModel>> getCertificates({
    String? studentId,
    String? batchId,
    String? type,
    String? status,
    int offset,
    int limit,
  });

  Future<void> issueCertificate({required Map<String, dynamic> body});

  Future<void> revokeCertificate({
    required String id,
    required String reason,
  });

  Future<List<CertificateTemplateModel>> getCertificateTemplates();

  Future<void> createCertificateTemplate({required Map<String, dynamic> body});
}

class CertificateRemoteDataSourceImpl implements CertificateRemoteDataSource {
  final Dio _dio;
  const CertificateRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CertificateModel>> getCertificates({
    String? studentId,
    String? batchId,
    String? type,
    String? status,
    int offset = 0,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'offset': offset, 'limit': limit};
    if (studentId != null) params['student_id'] = studentId;
    if (batchId != null) params['batch_id'] = batchId;
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;

    final res = await _dio.get('/certificates', queryParameters: params);
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .cast<Map<String, dynamic>>()
        .map(CertificateModel.fromJson)
        .toList();
  }

  @override
  Future<void> issueCertificate({required Map<String, dynamic> body}) async {
    await _dio.post('/certificates', data: body);
  }

  @override
  Future<void> revokeCertificate({
    required String id,
    required String reason,
  }) async {
    await _dio.post('/certificates/$id/revoke', data: {'reason': reason});
  }

  @override
  Future<List<CertificateTemplateModel>> getCertificateTemplates() async {
    final res = await _dio.get('/certificate-templates');
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .cast<Map<String, dynamic>>()
        .map(CertificateTemplateModel.fromJson)
        .toList();
  }

  @override
  Future<void> createCertificateTemplate({
    required Map<String, dynamic> body,
  }) async {
    await _dio.post('/certificate-templates', data: body);
  }
}
