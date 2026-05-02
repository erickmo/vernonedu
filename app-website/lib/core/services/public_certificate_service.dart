import 'package:dio/dio.dart';

import '../models/public_certificate_verification_model.dart';
import '../network/api_client.dart';

/// Thrown when the verify endpoint returns 404 — distinct from network/server errors
/// so the UI can show a friendly empty-state instead of a generic error.
class CertificateNotFoundException implements Exception {
  final String code;
  CertificateNotFoundException(this.code);
  @override
  String toString() => 'Certificate not found: $code';
}

/// Service for `GET /api/v1/public/certificates/verify/{code}` (PII-safe).
///
/// Throws [CertificateNotFoundException] on 404, generic [DioException] otherwise.
class PublicCertificateService {
  final Dio _dio;

  PublicCertificateService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Verify a certificate by its unique code via the PII-safe public endpoint.
  Future<PublicCertificateVerification> verifyCertificate(String code) async {
    try {
      final resp = await _dio.get('/public/certificates/verify/$code');
      final raw = resp.data;
      final json = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      return PublicCertificateVerification.fromJson(json);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw CertificateNotFoundException(code);
      }
      rethrow;
    }
  }
}
