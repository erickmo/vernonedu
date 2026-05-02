import 'package:dio/dio.dart';

import '../models/certificate_model.dart';
import '../models/certificate_template_model.dart';

/// Endpoint paths — kept as constants to avoid magic strings.
const _epCertificates = '/certificates';
const _epCertificatesParticipant = '/certificates/participant';
const _epCertificatesCompetency = '/certificates/competency';
const _epCertificateTemplates = '/certificate-templates';

String _epStudentCertificates(String id) => '/students/$id/certificates';
String _epBatchCertificates(String id) => '/batches/$id/certificates';
String _epRevoke(String id) => '/certificates/$id/revoke';

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

  /// Issues a participant certificate for a single student. Backend returns
  /// `{message: ...}`; no certificate payload is sent back.
  Future<void> issueParticipantSingle({
    required String batchId,
    required String studentId,
    required String courseId,
    String? templateId,
    String? verificationBaseUrl,
  });

  /// Issues a competency certificate. Backend requires `testPassed=true`.
  Future<void> issueCompetency({
    required String studentId,
    required String courseId,
    String? batchId,
    String? templateId,
    required bool testPassed,
    String? verificationBaseUrl,
  });

  Future<List<CertificateModel>> listByStudent(String studentId);
  Future<List<CertificateModel>> listByBatch(String batchId);

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

    final res = await _dio.get(_epCertificates, queryParameters: params);
    return _parseCertList(res.data);
  }

  @override
  Future<void> issueCertificate({required Map<String, dynamic> body}) async {
    await _dio.post(_epCertificates, data: body);
  }

  @override
  Future<void> issueParticipantSingle({
    required String batchId,
    required String studentId,
    required String courseId,
    String? templateId,
    String? verificationBaseUrl,
  }) async {
    final body = <String, dynamic>{
      'batchId': batchId,
      'studentId': studentId,
      'courseId': courseId,
    };
    if (templateId != null) body['templateId'] = templateId;
    if (verificationBaseUrl != null) {
      body['verificationBaseUrl'] = verificationBaseUrl;
    }
    await _dio.post(_epCertificatesParticipant, data: body);
  }

  @override
  Future<void> issueCompetency({
    required String studentId,
    required String courseId,
    String? batchId,
    String? templateId,
    required bool testPassed,
    String? verificationBaseUrl,
  }) async {
    final body = <String, dynamic>{
      'studentId': studentId,
      'courseId': courseId,
      'testPassed': testPassed,
    };
    if (batchId != null) body['batchId'] = batchId;
    if (templateId != null) body['templateId'] = templateId;
    if (verificationBaseUrl != null) {
      body['verificationBaseUrl'] = verificationBaseUrl;
    }
    await _dio.post(_epCertificatesCompetency, data: body);
  }

  @override
  Future<List<CertificateModel>> listByStudent(String studentId) async {
    final res = await _dio.get(_epStudentCertificates(studentId));
    return _parseCertList(res.data);
  }

  @override
  Future<List<CertificateModel>> listByBatch(String batchId) async {
    final res = await _dio.get(_epBatchCertificates(batchId));
    return _parseCertList(res.data);
  }

  @override
  Future<void> revokeCertificate({
    required String id,
    required String reason,
  }) async {
    await _dio.post(_epRevoke(id), data: {'reason': reason});
  }

  @override
  Future<List<CertificateTemplateModel>> getCertificateTemplates() async {
    final res = await _dio.get(_epCertificateTemplates);
    final list = _extractList(res.data);
    return list
        .cast<Map<String, dynamic>>()
        .map(CertificateTemplateModel.fromJson)
        .toList();
  }

  @override
  Future<void> createCertificateTemplate({
    required Map<String, dynamic> body,
  }) async {
    await _dio.post(_epCertificateTemplates, data: body);
  }
}

/// Shared list parser — handles both `{data:[..]}` envelopes and raw arrays.
List<CertificateModel> _parseCertList(dynamic raw) {
  final list = _extractList(raw);
  return list
      .cast<Map<String, dynamic>>()
      .map(CertificateModel.fromJson)
      .toList();
}

List<dynamic> _extractList(dynamic raw) {
  if (raw is Map && raw['data'] != null) return raw['data'] as List;
  if (raw is List) return raw;
  return const <dynamic>[];
}
