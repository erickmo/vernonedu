import 'package:dio/dio.dart';

import '../models/payable_model.dart';

abstract class PayableRemoteDataSource {
  Future<PayableStatsModel> getPayableStats();

  Future<List<PayableModel>> getPayables({
    int offset = 0,
    int limit = 20,
    String? type,
    String? status,
    String? batchId,
  });

  Future<PayableModel> getPayableById(String id);

  Future<void> markPayableAsPaid(String id, {String? paymentProof});
}

class PayableRemoteDataSourceImpl implements PayableRemoteDataSource {
  final Dio dio;
  const PayableRemoteDataSourceImpl(this.dio);

  @override
  Future<PayableStatsModel> getPayableStats() async {
    final res = await dio.get('/finance/payables/stats');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return PayableStatsModel.fromJson(json);
  }

  @override
  Future<List<PayableModel>> getPayables({
    int offset = 0,
    int limit = 20,
    String? type,
    String? status,
    String? batchId,
  }) async {
    final params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (batchId != null) 'batch_id': batchId,
    };
    final res = await dio.get('/finance/payables', queryParameters: params);
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => PayableModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PayableModel> getPayableById(String id) async {
    final res = await dio.get('/finance/payables/$id');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return PayableModel.fromJson(json);
  }

  @override
  Future<void> markPayableAsPaid(String id, {String? paymentProof}) async {
    await dio.put(
      '/finance/payables/$id/pay',
      data: {
        if (paymentProof != null) 'payment_proof': paymentProof,
      },
    );
  }
}
