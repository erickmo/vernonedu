import 'package:dio/dio.dart';

import '../models/public_enrollment_model.dart';
import '../network/api_client.dart';

/// Service for /api/v1/public/enrollment
class PublicEnrollmentService {
  final Dio _dio;

  PublicEnrollmentService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Submit enrollment form. Creates student + enrollment + invoice.
  Future<EnrollmentResponse> submitEnrollment(
    EnrollmentRequest request,
  ) async {
    final resp = await _dio.post(
      '/public/enrollment',
      data: request.toJson(),
    );
    final raw = resp.data;
    final json = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return EnrollmentResponse.fromJson(json);
  }

  /// Validate a referral code. Returns partner name if valid, null if not found.
  Future<String?> validateReferralCode(String code) async {
    try {
      final resp = await _dio.get(
        '/marketing/referral-partners',
        queryParameters: {'code': code},
      );
      final raw = resp.data;
      List list;
      if (raw is Map && raw['data'] != null) {
        final inner = raw['data'];
        list = inner is List ? inner : [];
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }
      if (list.isEmpty) return null;
      final partner = list.first as Map<String, dynamic>;
      return partner['name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
