import 'package:dio/dio.dart';

import '../models/public_course_model.dart';
import '../network/api_client.dart';

/// Service for /api/v1/public/courses and /api/v1/public/batches
class PublicCourseService {
  final Dio _dio;

  PublicCourseService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Fetch paginated public course list.
  /// [type] filters by course type: karir | reguler | privat | sertifikasi
  Future<PublicCourseListResult> fetchCourses({
    String? type,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final resp = await _dio.get(
        '/public/courses',
        queryParameters: {
          'offset': offset,
          'limit': limit,
          if (type != null) 'type': type,
        },
      );
      final raw = resp.data;
      final json = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      return PublicCourseListResult.fromJson(json);
    } on DioException {
      return PublicCourseListResult.mock();
    }
  }

  /// Fetch with full filter params (multi-type, price range, sort, etc.)
  Future<PublicCourseListResult> fetchCoursesFiltered({
    String? search,
    List<String>? types,
    String? departmentId,
    int? minPrice,
    int? maxPrice,
    String? scheduleAvailability,
    String? sortBy,
    int offset = 0,
    int limit = 12,
  }) async {
    try {
      final params = <String, dynamic>{
        'offset': offset,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (departmentId != null) params['department_id'] = departmentId;
      if (minPrice != null) params['min_price'] = minPrice;
      if (maxPrice != null) params['max_price'] = maxPrice;
      if (scheduleAvailability != null) {
        params['schedule'] = scheduleAvailability;
      }
      if (sortBy != null) params['sort'] = sortBy;
      if (types != null && types.isNotEmpty) {
        params['type'] = types.join(',');
      }

      final resp = await _dio.get(
        '/public/courses',
        queryParameters: params,
      );
      final raw = resp.data;
      final json = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      return PublicCourseListResult.fromJson(json);
    } on DioException {
      return PublicCourseListResult.mock();
    }
  }

  /// Fetch full course detail including available batches.
  Future<PublicCourseDetail> fetchCourseDetail(String courseId) async {
    try {
      final resp = await _dio.get('/public/courses/$courseId');
      final raw = resp.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return PublicCourseDetail.fromJson(json);
    } on DioException {
      return PublicCourseDetail(
        id: courseId,
        name: 'Web Development Fullstack',
        description: 'Kuasai pengembangan web dari frontend hingga backend.',
        field: 'teknologi',
        thumbnailUrl: '',
        departmentName: 'Web & Mobile Development',
        availableBatches: [PublicBatch.mock()],
        objectives: ['Membangun aplikasi web fullstack', 'Menguasai React.js'],
        requirements: ['Tidak perlu pengalaman sebelumnya'],
      );
    }
  }

  /// Fetch rich course detail V2 (with types, facilitators, testimonials, FAQ)
  Future<PublicCourseDetailV2> fetchCourseDetailV2(String courseId) async {
    try {
      final resp = await _dio.get('/public/courses/$courseId');
      final raw = resp.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return PublicCourseDetailV2.fromJson(json);
    } on DioException {
      return PublicCourseDetailV2.mock();
    }
  }

  /// Fetch single batch detail with schedules.
  Future<PublicBatch> fetchBatchDetail(String batchId) async {
    try {
      final resp = await _dio.get('/public/batches/$batchId');
      final raw = resp.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return PublicBatch.fromJson(json);
    } on DioException {
      return PublicBatch.mock();
    }
  }

  /// Fetch departments for filter dropdown
  Future<List<PublicDepartment>> fetchDepartments() async {
    try {
      final resp = await _dio.get('/public/departments');
      final raw = resp.data;
      final list = (raw is Map && raw['data'] != null)
          ? raw['data'] as List
          : raw is List
              ? raw
              : <dynamic>[];
      return list
          .map((e) => PublicDepartment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [
        const PublicDepartment(id: '1', name: 'Web & Mobile Development'),
        const PublicDepartment(id: '2', name: 'Data Science & AI'),
        const PublicDepartment(id: '3', name: 'UI/UX Design'),
        const PublicDepartment(id: '4', name: 'Digital Marketing'),
      ];
    }
  }
}
