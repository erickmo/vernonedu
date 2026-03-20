import 'package:dio/dio.dart';

import '../models/business_model.dart';

abstract class BusinessRemoteDataSource {
  Future<List<BusinessModel>> getBusinesses({int offset = 0, int limit = 20});

  Future<BusinessModel> getBusinessById({required String id});

  Future<void> createBusiness({required String name});

  Future<void> updateBusiness({required String id, required String name});

  Future<void> deleteBusiness({required String id});
}

class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  final Dio dio;

  BusinessRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<BusinessModel>> getBusinesses({
    int offset = 0,
    int limit = 20,
  }) async {
    final response = await dio.get(
      '/businesses',
      queryParameters: {'offset': offset, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>;
    return list
        .map((item) => BusinessModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BusinessModel> getBusinessById({required String id}) async {
    final response = await dio.get('/businesses/$id');
    final body = response.data as Map<String, dynamic>;
    return BusinessModel.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> createBusiness({required String name}) async {
    await dio.post('/businesses', data: {'name': name});
  }

  @override
  Future<void> updateBusiness({required String id, required String name}) async {
    await dio.put('/businesses/$id', data: {'name': name});
  }

  @override
  Future<void> deleteBusiness({required String id}) async {
    await dio.delete('/businesses/$id');
  }
}
