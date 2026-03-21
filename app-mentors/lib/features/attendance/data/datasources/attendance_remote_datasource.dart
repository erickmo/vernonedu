import 'package:dio/dio.dart';

import '../models/attendance_record_model.dart';
import '../models/attendance_session_model.dart';

abstract class AttendanceRemoteDataSource {
  /// GET /course-batches/:batchId/sessions
  Future<List<AttendanceSessionModel>> getSessions(String batchId);

  /// GET /course-batches/:batchId/sessions/:sessionId/attendance
  Future<List<AttendanceRecordModel>> getAttendanceRecords(
      String batchId, String sessionId);

  /// POST /course-batches/:batchId/sessions/:sessionId/attendance
  /// body: { records: [{student_id, status, note?}] }
  Future<void> submitAttendance(
    String batchId,
    String sessionId,
    List<AttendanceRecordModel> records,
  );
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final Dio _dio;

  const AttendanceRemoteDataSourceImpl(this._dio);

  @override
  Future<List<AttendanceSessionModel>> getSessions(String batchId) async {
    final res = await _dio.get('/course-batches/$batchId/sessions');
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => AttendanceSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AttendanceRecordModel>> getAttendanceRecords(
      String batchId, String sessionId) async {
    final res = await _dio
        .get('/course-batches/$batchId/sessions/$sessionId/attendance');
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map(
            (e) => AttendanceRecordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> submitAttendance(
    String batchId,
    String sessionId,
    List<AttendanceRecordModel> records,
  ) async {
    await _dio.post(
      '/course-batches/$batchId/sessions/$sessionId/attendance',
      data: {'records': records.map((r) => r.toJson()).toList()},
    );
  }
}
