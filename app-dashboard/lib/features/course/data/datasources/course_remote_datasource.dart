import 'package:dio/dio.dart';
import '../models/course_model.dart';

// Kontrak abstract datasource untuk MasterCourse
abstract class CourseRemoteDataSource {
  Future<List<CourseModel>> getCourses({
    int offset = 0,
    int limit = 20,
    String status = '',
    String field = '',
  });
  Future<CourseModel> getCourseById(String id);
  Future<void> createCourse(Map<String, dynamic> data);
  Future<void> updateCourse(String id, Map<String, dynamic> data);
  Future<void> archiveCourse(String id);
  Future<void> deleteCourse(String id);
}

// Implementasi datasource menggunakan Dio — endpoint: /api/v1/curriculum/courses
class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final Dio _dio;
  const CourseRemoteDataSourceImpl(this._dio);

  // GET /api/v1/curriculum/courses
  // Query params: offset, limit, status (opsional), field (opsional)
  @override
  Future<List<CourseModel>> getCourses({
    int offset = 0,
    int limit = 20,
    String status = '',
    String field = '',
  }) async {
    final params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
    };
    if (status.isNotEmpty) params['status'] = status;
    if (field.isNotEmpty) params['field'] = field;

    final res = await _dio.get(
      '/curriculum/courses',
      queryParameters: params,
    );
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data
        .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/v1/curriculum/courses/{id}
  // Response bisa berupa { data: {...} } atau langsung object — handle null-safe
  @override
  Future<CourseModel> getCourseById(String id) async {
    final res = await _dio.get('/curriculum/courses/$id');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return CourseModel.fromJson(json);
  }

  // POST /api/v1/curriculum/courses
  @override
  Future<void> createCourse(Map<String, dynamic> data) async {
    await _dio.post('/curriculum/courses', data: data);
  }

  // PUT /api/v1/curriculum/courses/{id}
  @override
  Future<void> updateCourse(String id, Map<String, dynamic> data) async {
    await _dio.put('/curriculum/courses/$id', data: data);
  }

  // POST /api/v1/curriculum/courses/{id}/archive
  @override
  Future<void> archiveCourse(String id) async {
    await _dio.post('/curriculum/courses/$id/archive');
  }

  // DELETE /api/v1/curriculum/courses/{id}
  @override
  Future<void> deleteCourse(String id) async {
    await _dio.delete('/curriculum/courses/$id');
  }
}
