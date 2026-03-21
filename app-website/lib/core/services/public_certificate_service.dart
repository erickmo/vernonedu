import 'package:dio/dio.dart';

import '../models/public_certificate_model.dart';
import '../network/api_client.dart';

/// Service for /api/v1/public/certificates/{code}
class PublicCertificateService {
  final Dio _dio;

  PublicCertificateService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Verify a certificate by its unique code.
  Future<CertificateVerification> verifyCertificate(String code) async {
    final resp = await _dio.get('/public/certificates/$code');
    final raw = resp.data;
    final json = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return CertificateVerification.fromJson(json);
  }
}
