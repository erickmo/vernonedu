import 'package:dio/dio.dart';
import '../models/course_batch_detail_model.dart';
import '../models/course_batch_model.dart';

abstract class CourseBatchRemoteDataSource {
  Future<List<CourseBatchModel>> getCourseBatches({int offset = 0, int limit = 20});
  Future<CourseBatchDetailModel> getCourseBatchDetail(String batchId);
  Future<void> createCourseBatch(Map<String, dynamic> data);
}

class CourseBatchRemoteDataSourceImpl implements CourseBatchRemoteDataSource {
  final Dio _dio;
  const CourseBatchRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CourseBatchModel>> getCourseBatches({int offset = 0, int limit = 20}) async {
    final res = await _dio.get('/course-batches', queryParameters: {'offset': offset, 'limit': limit});
    final data = (res.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => CourseBatchModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CourseBatchDetailModel> getCourseBatchDetail(String batchId) async {
    final res = await _dio.get('/course-batches/$batchId/detail');
    final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return CourseBatchDetailModel.fromJson(data);
  }

  @override
  Future<void> createCourseBatch(Map<String, dynamic> data) async {
    await _dio.post('/course-batches', data: data);
  }
}
