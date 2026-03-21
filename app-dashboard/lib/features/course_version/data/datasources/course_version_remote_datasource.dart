import 'package:dio/dio.dart';
import '../models/course_version_model.dart';
import '../models/internship_config_model.dart';
import '../models/character_test_config_model.dart';

// Kontrak abstract datasource untuk CourseVersion
abstract class CourseVersionRemoteDataSource {
  Future<List<CourseVersionModel>> getVersionsByType(String typeId);
  Future<CourseVersionModel> getVersionById(String versionId);
  Future<void> createVersion(String typeId, Map<String, dynamic> data);

  // POST /api/v1/curriculum/versions/{versionId}/promote
  // body: {"target_status": "review" | "approved"}
  Future<void> promoteVersion(String versionId, String targetStatus);

  // GET /api/v1/curriculum/versions/{versionId}/internship
  Future<InternshipConfigModel?> getInternshipConfig(String versionId);

  // PUT /api/v1/curriculum/versions/{versionId}/internship
  Future<void> upsertInternshipConfig(String versionId, Map<String, dynamic> data);

  // GET /api/v1/curriculum/versions/{versionId}/character-test
  Future<CharacterTestConfigModel?> getCharacterTestConfig(String versionId);

  // PUT /api/v1/curriculum/versions/{versionId}/character-test
  Future<void> upsertCharacterTestConfig(String versionId, Map<String, dynamic> data);
}

// Implementasi datasource menggunakan Dio
class CourseVersionRemoteDataSourceImpl implements CourseVersionRemoteDataSource {
  final Dio _dio;
  const CourseVersionRemoteDataSourceImpl(this._dio);

  // GET /api/v1/curriculum/types/{typeId}/versions
  @override
  Future<List<CourseVersionModel>> getVersionsByType(String typeId) async {
    final res = await _dio.get('/curriculum/types/$typeId/versions');
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => CourseVersionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // GET /api/v1/curriculum/versions/{versionId}
  @override
  Future<CourseVersionModel> getVersionById(String versionId) async {
    final res = await _dio.get('/curriculum/versions/$versionId');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return CourseVersionModel.fromJson(json);
  }

  // POST /api/v1/curriculum/types/{typeId}/versions
  @override
  Future<void> createVersion(String typeId, Map<String, dynamic> data) async {
    await _dio.post('/curriculum/types/$typeId/versions', data: data);
  }

  // POST /api/v1/curriculum/versions/{versionId}/promote
  @override
  Future<void> promoteVersion(String versionId, String targetStatus) async {
    await _dio.post(
      '/curriculum/versions/$versionId/promote',
      data: {'target_status': targetStatus},
    );
  }

  // GET /api/v1/curriculum/versions/{versionId}/internship
  @override
  Future<InternshipConfigModel?> getInternshipConfig(String versionId) async {
    try {
      final res = await _dio.get('/curriculum/versions/$versionId/internship');
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return InternshipConfigModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // PUT /api/v1/curriculum/versions/{versionId}/internship
  @override
  Future<void> upsertInternshipConfig(String versionId, Map<String, dynamic> data) async {
    await _dio.put('/curriculum/versions/$versionId/internship', data: data);
  }

  // GET /api/v1/curriculum/versions/{versionId}/character-test
  @override
  Future<CharacterTestConfigModel?> getCharacterTestConfig(String versionId) async {
    try {
      final res = await _dio.get('/curriculum/versions/$versionId/character-test');
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return CharacterTestConfigModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // PUT /api/v1/curriculum/versions/{versionId}/character-test
  @override
  Future<void> upsertCharacterTestConfig(String versionId, Map<String, dynamic> data) async {
    await _dio.put('/curriculum/versions/$versionId/character-test', data: data);
  }
}
