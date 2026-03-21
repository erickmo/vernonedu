import 'package:dio/dio.dart';
import '../models/marketing_stats_model.dart';
import '../models/social_media_post_model.dart';
import '../models/class_doc_post_model.dart';
import '../models/pr_schedule_model.dart';
import '../models/referral_partner_model.dart';
import '../models/referral_model.dart';

abstract class MarketingRemoteDataSource {
  Future<MarketingStatsModel> getStats();
  Future<List<SocialMediaPostModel>> getPosts({
    String platform,
    String status,
    String month,
  });
  Future<void> createPost(Map<String, dynamic> data);
  Future<void> updatePost(String id, Map<String, dynamic> data);
  Future<void> submitPostUrl(String id, String url);
  Future<void> deletePost(String id);
  Future<List<ClassDocPostModel>> getClassDocs({String? status});
  Future<List<PrScheduleModel>> getPr({String? status, String? type});
  Future<void> createPr(Map<String, dynamic> data);
  Future<void> updatePr(String id, Map<String, dynamic> data);
  Future<void> deletePr(String id);
  Future<List<ReferralPartnerModel>> getReferralPartners();
  Future<void> createReferralPartner(Map<String, dynamic> data);
  Future<void> updateReferralPartner(String id, Map<String, dynamic> data);
  Future<List<ReferralModel>> getReferrals(String partnerId);
}

class MarketingRemoteDataSourceImpl implements MarketingRemoteDataSource {
  final Dio _dio;
  const MarketingRemoteDataSourceImpl(this._dio);

  List _parseList(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final inner = raw['data'];
      if (inner is Map && inner['data'] != null) {
        return inner['data'] as List;
      } else if (inner is List) {
        return inner;
      }
      return [];
    } else if (raw is List) {
      return raw;
    }
    return [];
  }

  Map<String, dynamic> _parseSingle(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      return raw['data'] as Map<String, dynamic>;
    }
    return raw as Map<String, dynamic>;
  }

  @override
  Future<MarketingStatsModel> getStats() async {
    final res = await _dio.get('/marketing/stats');
    return MarketingStatsModel.fromJson(_parseSingle(res.data));
  }

  @override
  Future<List<SocialMediaPostModel>> getPosts({
    String platform = '',
    String status = '',
    String month = '',
  }) async {
    final params = <String, dynamic>{};
    if (platform.isNotEmpty) params['platform'] = platform;
    if (status.isNotEmpty) params['status'] = status;
    if (month.isNotEmpty) params['month'] = month;

    final res = await _dio.get('/marketing/posts', queryParameters: params);
    final list = _parseList(res.data);
    return list
        .map((e) => SocialMediaPostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createPost(Map<String, dynamic> data) async {
    await _dio.post('/marketing/posts', data: data);
  }

  @override
  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    await _dio.put('/marketing/posts/$id', data: data);
  }

  @override
  Future<void> submitPostUrl(String id, String url) async {
    await _dio.put('/marketing/posts/$id/submit-url', data: {'url': url});
  }

  @override
  Future<void> deletePost(String id) async {
    await _dio.delete('/marketing/posts/$id');
  }

  @override
  Future<List<ClassDocPostModel>> getClassDocs({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;

    final res =
        await _dio.get('/marketing/class-docs', queryParameters: params);
    final list = _parseList(res.data);
    return list
        .map((e) => ClassDocPostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PrScheduleModel>> getPr({
    String? status,
    String? type,
  }) async {
    final params = <String, dynamic>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (type != null && type.isNotEmpty) params['type'] = type;

    final res = await _dio.get('/marketing/pr', queryParameters: params);
    final list = _parseList(res.data);
    return list
        .map((e) => PrScheduleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createPr(Map<String, dynamic> data) async {
    await _dio.post('/marketing/pr', data: data);
  }

  @override
  Future<void> updatePr(String id, Map<String, dynamic> data) async {
    await _dio.put('/marketing/pr/$id', data: data);
  }

  @override
  Future<void> deletePr(String id) async {
    await _dio.delete('/marketing/pr/$id');
  }

  @override
  Future<List<ReferralPartnerModel>> getReferralPartners() async {
    final res = await _dio.get('/marketing/referral-partners');
    final list = _parseList(res.data);
    return list
        .map((e) => ReferralPartnerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createReferralPartner(Map<String, dynamic> data) async {
    await _dio.post('/marketing/referral-partners', data: data);
  }

  @override
  Future<void> updateReferralPartner(
      String id, Map<String, dynamic> data) async {
    await _dio.put('/marketing/referral-partners/$id', data: data);
  }

  @override
  Future<List<ReferralModel>> getReferrals(String partnerId) async {
    final res =
        await _dio.get('/marketing/referral-partners/$partnerId/referrals');
    final list = _parseList(res.data);
    return list
        .map((e) => ReferralModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
