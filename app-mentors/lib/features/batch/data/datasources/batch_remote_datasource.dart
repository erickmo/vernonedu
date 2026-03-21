import 'package:dio/dio.dart';

import '../models/batch_detail_model.dart';
import '../models/batch_model.dart';

abstract class BatchRemoteDataSource {
  /// GET /course-batches?facilitator_id=me  or  GET /course-batches/my
  Future<List<BatchModel>> getMyBatches();

  /// GET /course-batches/:id/detail
  Future<BatchDetailModel> getBatchDetail(String batchId);

  /// PUT /course-batches/:id/facilitator
  Future<void> assignFacilitator(String batchId, String facilitatorId);
}

class BatchRemoteDataSourceImpl implements BatchRemoteDataSource {
  final Dio _dio;

  const BatchRemoteDataSourceImpl(this._dio);

  @override
  Future<List<BatchModel>> getMyBatches() async {
    final res = await _dio.get('/course-batches/my');
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => BatchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BatchDetailModel> getBatchDetail(String batchId) async {
    final res = await _dio.get('/course-batches/$batchId/detail');
    final raw = res.data as Map<String, dynamic>;
    final data = raw['data'] as Map<String, dynamic>? ?? raw;
    return BatchDetailModel.fromJson(data);
  }

  @override
  Future<void> assignFacilitator(String batchId, String facilitatorId) async {
    await _dio.put(
      '/course-batches/$batchId/facilitator',
      data: {'facilitator_id': facilitatorId},
    );
  }
}
