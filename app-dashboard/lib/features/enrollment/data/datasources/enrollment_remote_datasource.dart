import 'package:dio/dio.dart';
import '../models/enrollment_batch_summary_model.dart';
import '../models/enrollment_model.dart';

abstract class EnrollmentRemoteDataSource {
  Future<List<EnrollmentModel>> getEnrollments({int offset = 0, int limit = 20});
  Future<List<EnrollmentBatchSummaryModel>> getEnrollmentSummary();
  Future<void> enrollStudent(Map<String, dynamic> data);
  Future<void> updateEnrollmentStatus(String id, String status);
  Future<void> updateEnrollmentPaymentStatus(String id, String paymentStatus);
}

class EnrollmentRemoteDataSourceImpl implements EnrollmentRemoteDataSource {
  final Dio _dio;
  const EnrollmentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<EnrollmentModel>> getEnrollments({int offset = 0, int limit = 20}) async {
    final res = await _dio.get('/enrollments', queryParameters: {'offset': offset, 'limit': limit});
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => EnrollmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<EnrollmentBatchSummaryModel>> getEnrollmentSummary() async {
    final res = await _dio.get('/enrollments/summary');
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => EnrollmentBatchSummaryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> enrollStudent(Map<String, dynamic> data) async {
    await _dio.post('/enrollments', data: data);
  }

  @override
  Future<void> updateEnrollmentStatus(String id, String status) async {
    await _dio.put('/enrollments/$id/status', data: {'status': status});
  }

  @override
  Future<void> updateEnrollmentPaymentStatus(String id, String paymentStatus) async {
    await _dio.put('/enrollments/$id/payment-status', data: {'payment_status': paymentStatus});
  }
}
