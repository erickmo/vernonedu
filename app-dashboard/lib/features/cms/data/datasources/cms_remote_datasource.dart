import 'package:dio/dio.dart';
import '../models/cms_page_model.dart';
import '../models/cms_article_model.dart';
import '../models/cms_testimonial_model.dart';
import '../models/cms_faq_model.dart';
import '../models/cms_media_model.dart';

abstract class CmsRemoteDataSource {
  Future<List<CmsPageModel>> getPages();
  Future<CmsPageModel> getPage(String slug);
  Future<void> updatePage(String slug, Map<String, dynamic> data);
  Future<Map<String, dynamic>> getArticles({
    int offset = 0,
    int limit = 15,
    String? category,
    String? status,
  });
  Future<void> createArticle(Map<String, dynamic> data);
  Future<void> updateArticle(String id, Map<String, dynamic> data);
  Future<void> deleteArticle(String id);
  Future<List<CmsTestimonialModel>> getTestimonials();
  Future<void> createTestimonial(Map<String, dynamic> data);
  Future<void> updateTestimonial(String id, Map<String, dynamic> data);
  Future<void> deleteTestimonial(String id);
  Future<List<CmsFaqModel>> getFaq({String? category});
  Future<void> createFaq(Map<String, dynamic> data);
  Future<void> updateFaq(String id, Map<String, dynamic> data);
  Future<void> deleteFaq(String id);
  Future<List<CmsMediaModel>> getMedia();
  Future<void> deleteMedia(String id);
}

class CmsRemoteDataSourceImpl implements CmsRemoteDataSource {
  final Dio _dio;
  const CmsRemoteDataSourceImpl(this._dio);

  List _extractList(dynamic raw) {
    if (raw is Map && raw['data'] != null) {
      final inner = raw['data'];
      if (inner is List) return inner;
      if (inner is Map && inner['data'] != null) return inner['data'] as List;
    }
    if (raw is List) return raw;
    return [];
  }

  @override
  Future<List<CmsPageModel>> getPages() async {
    final res = await _dio.get('/cms/pages');
    return _extractList(res.data)
        .map((e) => CmsPageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CmsPageModel> getPage(String slug) async {
    final res = await _dio.get('/cms/pages/$slug');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return CmsPageModel.fromJson(json);
  }

  @override
  Future<void> updatePage(String slug, Map<String, dynamic> data) async {
    await _dio.put('/cms/pages/$slug', data: data);
  }

  @override
  Future<Map<String, dynamic>> getArticles({
    int offset = 0,
    int limit = 15,
    String? category,
    String? status,
  }) async {
    final params = <String, dynamic>{'offset': offset, 'limit': limit};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final res = await _dio.get('/cms/articles', queryParameters: params);
    final raw = res.data;
    List list;
    int total = 0;
    if (raw is Map && raw['data'] != null) {
      final inner = raw['data'];
      if (inner is Map) {
        list = (inner['data'] as List?) ?? [];
        total = (inner['total'] as num?)?.toInt() ?? list.length;
      } else if (inner is List) {
        list = inner;
        total = list.length;
      } else {
        list = [];
      }
    } else if (raw is List) {
      list = raw;
      total = list.length;
    } else {
      list = [];
    }
    return {
      'data': list.map((e) => CmsArticleModel.fromJson(e as Map<String, dynamic>)).toList(),
      'total': total,
    };
  }

  @override
  Future<void> createArticle(Map<String, dynamic> data) async {
    await _dio.post('/cms/articles', data: data);
  }

  @override
  Future<void> updateArticle(String id, Map<String, dynamic> data) async {
    await _dio.put('/cms/articles/$id', data: data);
  }

  @override
  Future<void> deleteArticle(String id) async {
    await _dio.delete('/cms/articles/$id');
  }

  @override
  Future<List<CmsTestimonialModel>> getTestimonials() async {
    final res = await _dio.get('/cms/testimonials');
    return _extractList(res.data)
        .map((e) => CmsTestimonialModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createTestimonial(Map<String, dynamic> data) async {
    await _dio.post('/cms/testimonials', data: data);
  }

  @override
  Future<void> updateTestimonial(String id, Map<String, dynamic> data) async {
    await _dio.put('/cms/testimonials/$id', data: data);
  }

  @override
  Future<void> deleteTestimonial(String id) async {
    await _dio.delete('/cms/testimonials/$id');
  }

  @override
  Future<List<CmsFaqModel>> getFaq({String? category}) async {
    final params = <String, dynamic>{};
    if (category != null && category.isNotEmpty) params['category'] = category;
    final res = await _dio.get('/cms/faq', queryParameters: params);
    return _extractList(res.data)
        .map((e) => CmsFaqModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createFaq(Map<String, dynamic> data) async {
    await _dio.post('/cms/faq', data: data);
  }

  @override
  Future<void> updateFaq(String id, Map<String, dynamic> data) async {
    await _dio.put('/cms/faq/$id', data: data);
  }

  @override
  Future<void> deleteFaq(String id) async {
    await _dio.delete('/cms/faq/$id');
  }

  @override
  Future<List<CmsMediaModel>> getMedia() async {
    final res = await _dio.get('/cms/media');
    return _extractList(res.data)
        .map((e) => CmsMediaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteMedia(String id) async {
    await _dio.delete('/cms/media/$id');
  }
}
