import 'package:dio/dio.dart';
import '../models/department_model.dart';
import '../models/department_summary_model.dart';
import '../models/department_batch_model.dart';
import '../models/department_course_model.dart';
import '../models/department_student_model.dart';
import '../models/department_talentpool_model.dart';

abstract class DepartmentRemoteDataSource {
  Future<List<DepartmentModel>> getDepartments({int offset = 0, int limit = 100});
  Future<void> createDepartment(Map<String, dynamic> data);
  Future<void> updateDepartment(String id, Map<String, dynamic> data);
  Future<void> deleteDepartment(String id);

  Future<List<DepartmentSummaryModel>> getDepartmentSummaries();
  Future<List<DepartmentBatchModel>> getDepartmentBatches(String departmentId);
  Future<List<DepartmentCourseModel>> getDepartmentCourses(String departmentId);
  Future<List<DepartmentStudentModel>> getDepartmentStudents(String departmentId, {String status = ''});
  Future<List<DepartmentTalentPoolModel>> getDepartmentTalentPool(String departmentId);
  Future<void> assignBatchFacilitator(String batchId, String facilitatorId);
}

class DepartmentRemoteDataSourceImpl implements DepartmentRemoteDataSource {
  final Dio _dio;
  const DepartmentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<DepartmentModel>> getDepartments({int offset = 0, int limit = 100}) async {
    final res = await _dio.get('/departments', queryParameters: {'offset': offset, 'limit': limit});
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> createDepartment(Map<String, dynamic> data) async {
    // API returns {"message": "department created successfully"} — no data to parse
    await _dio.post('/departments', data: data);
  }

  @override
  Future<void> updateDepartment(String id, Map<String, dynamic> data) async {
    // API returns {"message": "department updated successfully"} — no data to parse
    await _dio.put('/departments/$id', data: data);
  }

  @override
  Future<void> deleteDepartment(String id) async {
    await _dio.delete('/departments/$id');
  }

  @override
  Future<List<DepartmentSummaryModel>> getDepartmentSummaries() async {
    final res = await _dio.get('/departments/summaries');
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => DepartmentSummaryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<DepartmentBatchModel>> getDepartmentBatches(String departmentId) async {
    final res = await _dio.get('/departments/$departmentId/batches');
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => DepartmentBatchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<DepartmentCourseModel>> getDepartmentCourses(String departmentId) async {
    final res = await _dio.get('/departments/$departmentId/courses');
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => DepartmentCourseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<DepartmentStudentModel>> getDepartmentStudents(String departmentId, {String status = ''}) async {
    final params = <String, dynamic>{};
    if (status.isNotEmpty) params['status'] = status;
    final res = await _dio.get('/departments/$departmentId/students', queryParameters: params);
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => DepartmentStudentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<DepartmentTalentPoolModel>> getDepartmentTalentPool(String departmentId) async {
    final res = await _dio.get('/departments/$departmentId/talentpool');
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => DepartmentTalentPoolModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> assignBatchFacilitator(String batchId, String facilitatorId) async {
    await _dio.put('/course-batches/$batchId/facilitator', data: {'facilitator_id': facilitatorId});
  }
}
