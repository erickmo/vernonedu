import 'package:dio/dio.dart';
import '../models/course_module_model.dart';

// Kontrak abstract datasource untuk CourseModule
abstract class CourseModuleRemoteDataSource {
  Future<List<CourseModuleModel>> getModulesByVersion(String versionId);
  Future<void> createModule(String versionId, Map<String, dynamic> data);
  Future<void> updateModule(String moduleId, Map<String, dynamic> data);
  Future<void> deleteModule(String moduleId);
}

// Implementasi datasource menggunakan Dio — endpoint: /api/v1/curriculum/modules
class CourseModuleRemoteDataSourceImpl implements CourseModuleRemoteDataSource {
  final Dio _dio;
  const CourseModuleRemoteDataSourceImpl(this._dio);

  // GET /api/v1/curriculum/versions/{versionId}/modules
  @override
  Future<List<CourseModuleModel>> getModulesByVersion(String versionId) async {
    final res = await _dio.get('/curriculum/versions/$versionId/modules');
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => CourseModuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /api/v1/curriculum/versions/{versionId}/modules
  @override
  Future<void> createModule(String versionId, Map<String, dynamic> data) async {
    await _dio.post('/curriculum/versions/$versionId/modules', data: data);
  }

  // PUT /api/v1/curriculum/modules/{moduleId}
  @override
  Future<void> updateModule(String moduleId, Map<String, dynamic> data) async {
    await _dio.put('/curriculum/modules/$moduleId', data: data);
  }

  // DELETE /api/v1/curriculum/modules/{moduleId}
  @override
  Future<void> deleteModule(String moduleId) async {
    await _dio.delete('/curriculum/modules/$moduleId');
  }
}
