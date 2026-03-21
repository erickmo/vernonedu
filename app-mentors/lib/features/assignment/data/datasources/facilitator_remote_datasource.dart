import 'package:dio/dio.dart';

import '../models/facilitator_model.dart';

abstract class FacilitatorRemoteDataSource {
  /// GET /users?role=facilitator
  Future<List<FacilitatorModel>> getFacilitators();
}

class FacilitatorRemoteDataSourceImpl implements FacilitatorRemoteDataSource {
  final Dio _dio;

  const FacilitatorRemoteDataSourceImpl(this._dio);

  @override
  Future<List<FacilitatorModel>> getFacilitators() async {
    final res = await _dio.get('/users', queryParameters: {'role': 'facilitator'});
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => FacilitatorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
