import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../models/sdm_model.dart';

abstract class SdmRemoteDataSource {
  Future<List<SdmModel>> getSdmList();
  Future<SdmDetailModel> getSdmDetail(String id);
}

class SdmRemoteDataSourceImpl implements SdmRemoteDataSource {
  final Dio _dio;

  const SdmRemoteDataSourceImpl(this._dio);

  @override
  Future<List<SdmModel>> getSdmList() async {
    try {
      final response = await _dio.get('/hrm/sdm');
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list
          .map((e) => SdmModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerFailure(
        e.response?.data?['message'] as String? ?? 'Gagal memuat data SDM',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<SdmDetailModel> getSdmDetail(String id) async {
    try {
      final response = await _dio.get('/hrm/sdm/$id');
      final data = response.data as Map<String, dynamic>;
      return SdmDetailModel.fromJson(data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerFailure(
        e.response?.data?['message'] as String? ?? 'Gagal memuat detail SDM',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
