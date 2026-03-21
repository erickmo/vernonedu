import 'package:dio/dio.dart';

import '../models/public_enrollment_model.dart';
import '../network/api_client.dart';

/// Service for /api/v1/public/contact
class PublicContactService {
  final Dio _dio;

  PublicContactService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Submit contact form message.
  Future<void> submitContact(ContactRequest request) async {
    await _dio.post('/public/contact', data: request.toJson());
  }
}
