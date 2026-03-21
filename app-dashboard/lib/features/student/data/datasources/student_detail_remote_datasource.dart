import 'package:dio/dio.dart';

import '../models/student_detail_model.dart';
import '../models/student_enrollment_history_model.dart';
import '../models/student_note_model.dart';
import '../models/recommended_course_model.dart';

abstract class StudentDetailRemoteDataSource {
  Future<StudentDetailModel> getStudentDetail(String id);
  Future<List<StudentEnrollmentHistoryModel>> getStudentEnrollmentHistory(
      String studentId);
  Future<List<RecommendedCourseModel>> getStudentRecommendations(
      String studentId);
  Future<List<StudentNoteModel>> getStudentNotes(String studentId);
  Future<StudentNoteModel> addStudentNote(String studentId, String content);
  Future<void> updateStudent(
    String id, {
    required String name,
    required String email,
    required String phone,
  });
}

class StudentDetailRemoteDataSourceImpl
    implements StudentDetailRemoteDataSource {
  final Dio _dio;

  const StudentDetailRemoteDataSourceImpl(this._dio);

  @override
  Future<StudentDetailModel> getStudentDetail(String id) async {
    final res = await _dio.get('/students/$id');
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return StudentDetailModel.fromJson(data);
  }

  @override
  Future<List<StudentEnrollmentHistoryModel>> getStudentEnrollmentHistory(
      String studentId) async {
    final res = await _dio.get('/students/$studentId/enrollment-history');
    final raw = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    if (raw is! List) return [];
    return raw
        .map((j) =>
            StudentEnrollmentHistoryModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RecommendedCourseModel>> getStudentRecommendations(
      String studentId) async {
    final res = await _dio.get('/students/$studentId/recommendations');
    final raw = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    if (raw is! List) return [];
    return raw
        .map((j) =>
            RecommendedCourseModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<StudentNoteModel>> getStudentNotes(String studentId) async {
    final res = await _dio.get('/students/$studentId/notes');
    final raw = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    if (raw is! List) return [];
    return raw
        .map((j) => StudentNoteModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StudentNoteModel> addStudentNote(
      String studentId, String content) async {
    final res = await _dio.post(
      '/students/$studentId/notes',
      data: {'content': content},
    );
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return StudentNoteModel.fromJson(data);
  }

  @override
  Future<void> updateStudent(
    String id, {
    required String name,
    required String email,
    required String phone,
  }) async {
    await _dio.put('/students/$id', data: {
      'name': name,
      'email': email,
      'phone': phone,
    });
  }
}
