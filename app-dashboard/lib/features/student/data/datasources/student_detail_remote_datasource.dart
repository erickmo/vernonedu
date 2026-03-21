import 'package:dio/dio.dart';

import '../models/student_detail_model.dart';
import '../models/student_enrollment_history_model.dart';
import '../models/student_note_model.dart';
import '../models/recommended_course_model.dart';
import '../models/student_crm_log_model.dart';

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
    String? nik,
    String? gender,
    String? address,
    String? birthDate,
    String? departmentId,
    required String status,
    String? studentCode,
  });
  Future<List<StudentCrmLogModel>> getStudentCrmLogs(String studentId);
  Future<StudentCrmLogModel> addStudentCrmLog(
    String studentId, {
    required String contactMethod,
    required String response,
    String? contactedBy,
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
    String? nik,
    String? gender,
    String? address,
    String? birthDate,
    String? departmentId,
    required String status,
    String? studentCode,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
    };
    if (nik != null && nik.isNotEmpty) body['nik'] = nik;
    if (gender != null && gender.isNotEmpty) body['gender'] = gender;
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (birthDate != null && birthDate.isNotEmpty) body['birth_date'] = birthDate;
    if (departmentId != null && departmentId.isNotEmpty) {
      body['department_id'] = departmentId;
    }
    if (studentCode != null && studentCode.isNotEmpty) {
      body['student_code'] = studentCode;
    }
    await _dio.put('/students/$id', data: body);
  }

  @override
  Future<List<StudentCrmLogModel>> getStudentCrmLogs(String studentId) async {
    final res = await _dio.get('/students/$studentId/crm-logs');
    final raw = res.data is Map && res.data['data'] != null
        ? res.data['data']
        : res.data;
    List list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['data'] != null) {
      list = raw['data'] as List;
    } else {
      list = [];
    }
    return list
        .map((j) => StudentCrmLogModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StudentCrmLogModel> addStudentCrmLog(
    String studentId, {
    required String contactMethod,
    required String response,
    String? contactedBy,
  }) async {
    final body = <String, dynamic>{
      'contact_method': contactMethod,
      'response': response,
    };
    if (contactedBy != null && contactedBy.isNotEmpty) {
      body['contacted_by'] = contactedBy;
    }
    final res = await _dio.post('/students/$studentId/crm-logs', data: body);
    final data = res.data is Map && res.data['data'] != null
        ? res.data['data'] as Map<String, dynamic>
        : res.data as Map<String, dynamic>;
    return StudentCrmLogModel.fromJson(data);
  }
}
