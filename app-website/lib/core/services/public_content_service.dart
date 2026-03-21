import 'package:dio/dio.dart';

import '../models/public_content_model.dart';
import '../network/api_client.dart';

/// Service for /api/v1/public/pages, articles, testimonials, faq, stats
class PublicContentService {
  final Dio _dio;

  PublicContentService({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Fetch CMS-managed page content by slug.
  Future<PageContent> fetchPage(String slug) async {
    final resp = await _dio.get('/public/pages/$slug');
    final raw = resp.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return PageContent.fromJson(json);
  }

  /// Fetch paginated articles (blog posts).
  Future<ArticleListResult> fetchArticles({
    String? category,
    int offset = 0,
    int limit = 10,
  }) async {
    final resp = await _dio.get(
      '/public/articles',
      queryParameters: {
        'offset': offset,
        'limit': limit,
        if (category != null) 'category': category,
      },
    );
    final raw = resp.data;
    final json = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return ArticleListResult.fromJson(json);
  }

  /// Fetch testimonials. [courseId] to filter by course, [limit] default 10.
  Future<List<Testimonial>> fetchTestimonials({
    String? courseId,
    bool featuredOnly = false,
    int limit = 10,
  }) async {
    final resp = await _dio.get(
      '/public/testimonials',
      queryParameters: {
        'limit': limit,
        if (courseId != null) 'course_id': courseId,
        if (featuredOnly) 'is_featured': true,
      },
    );
    final raw = resp.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => Testimonial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch FAQ items. [category] or [pageSlug] to filter.
  Future<List<FaqItem>> fetchFaq({String? category, String? pageSlug}) async {
    final resp = await _dio.get(
      '/public/faq',
      queryParameters: {
        if (category != null) 'category': category,
        if (pageSlug != null) 'page_slug': pageSlug,
      },
    );
    final raw = resp.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch aggregate site statistics (student count, course count, etc.).
  Future<SiteStats> fetchStats() async {
    final resp = await _dio.get('/public/stats');
    final raw = resp.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return SiteStats.fromJson(json);
  }
}
