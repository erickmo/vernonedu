import 'package:dio/dio.dart';
import '../models/course_type_model.dart';

// Kontrak abstract datasource untuk CourseType
abstract class CourseTypeRemoteDataSource {
  Future<List<CourseTypeModel>> getTypesByCourse(String courseId);
  Future<CourseTypeModel> getTypeById(String typeId);
  Future<void> createType(String courseId, Map<String, dynamic> data);
  Future<void> updateType(String typeId, Map<String, dynamic> data);

  // POST /api/v1/curriculum/types/{typeId}/toggle — aktifkan/nonaktifkan tipe
  Future<void> toggleType(String typeId);
}

// Implementasi datasource menggunakan Dio — endpoint: /api/v1/curriculum/types
class CourseTypeRemoteDataSourceImpl implements CourseTypeRemoteDataSource {
  final Dio _dio;
  const CourseTypeRemoteDataSourceImpl(this._dio);

  // GET /api/v1/curriculum/courses/{courseId}/types
  @override
  Future<List<CourseTypeModel>> getTypesByCourse(String courseId) async {
    final res = await _dio.get('/curriculum/courses/$courseId/types');
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => CourseTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/v1/curriculum/types/{typeId}
  @override
  Future<CourseTypeModel> getTypeById(String typeId) async {
    final res = await _dio.get('/curriculum/types/$typeId');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return CourseTypeModel.fromJson(json);
  }

  // POST /api/v1/curriculum/courses/{courseId}/types
  @override
  Future<void> createType(String courseId, Map<String, dynamic> data) async {
    await _dio.post('/curriculum/courses/$courseId/types', data: data);
  }

  // PUT /api/v1/curriculum/types/{typeId}
  @override
  Future<void> updateType(String typeId, Map<String, dynamic> data) async {
    await _dio.put('/curriculum/types/$typeId', data: data);
  }

  // POST /api/v1/curriculum/types/{typeId}/toggle
  @override
  Future<void> toggleType(String typeId) async {
    await _dio.post('/curriculum/types/$typeId/toggle');
  }
}
