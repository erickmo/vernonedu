import 'package:dio/dio.dart';

import '../models/partner_detail_model.dart';

abstract class PartnerDetailRemoteDataSource {
  Future<PartnerDetailModel> getPartnerDetail(String partnerId);
  Future<void> addMOU(String partnerId, Map<String, dynamic> body);
}

class PartnerDetailRemoteDataSourceImpl implements PartnerDetailRemoteDataSource {
  final Dio _dio;

  const PartnerDetailRemoteDataSourceImpl(this._dio);

  @override
  Future<PartnerDetailModel> getPartnerDetail(String partnerId) async {
    final res = await _dio.get('/partners/$partnerId');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return PartnerDetailModel.fromJson(json);
  }

  @override
  Future<void> addMOU(String partnerId, Map<String, dynamic> body) async {
    await _dio.post('/partners/$partnerId/mou', data: body);
  }
}
