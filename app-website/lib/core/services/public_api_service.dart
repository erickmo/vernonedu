import 'package:dio/dio.dart';

import '../models/public_course_model.dart';
import '../models/public_enrollment_model.dart';

/// Article from /api/v1/public/articles
class PublicArticle {
  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String content;
  final String category;
  final String author;
  final String publishedAt;
  final String imageUrl;
  final List<String> tags;
  final bool isFeatured;

  const PublicArticle({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.category,
    required this.author,
    required this.publishedAt,
    required this.imageUrl,
    required this.tags,
    required this.isFeatured,
  });

  factory PublicArticle.fromJson(Map<String, dynamic> json) => PublicArticle(
        id: json['id'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        excerpt: json['excerpt'] as String? ?? '',
        content: json['content'] as String? ?? '',
        category: json['category'] as String? ?? '',
        author: json['author'] as String? ?? 'Tim VernonEdu',
        publishedAt: json['published_at'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        isFeatured: json['is_featured'] as bool? ?? false,
      );

  String get authorInitial {
    final parts = author.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return author.isNotEmpty ? author[0].toUpperCase() : 'VE';
  }
}

/// FAQ item from /api/v1/public/faq
class PublicFaq {
  final String id;
  final String question;
  final String answer;
  final String category;

  const PublicFaq({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
  });

  factory PublicFaq.fromJson(Map<String, dynamic> json) => PublicFaq(
        id: json['id'] as String? ?? '',
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        category: json['category'] as String? ?? '',
      );
}

/// Model untuk stats publik dari /api/v1/public/stats
class PublicStats {
  final int students;
  final int courses;
  final int partners;
  final int branches;

  const PublicStats({
    required this.students,
    required this.courses,
    required this.partners,
    required this.branches,
  });

  factory PublicStats.fromJson(Map<String, dynamic> json) => PublicStats(
        students: (json['students'] as num?)?.toInt() ?? 0,
        courses: (json['courses'] as num?)?.toInt() ?? 0,
        partners: (json['partners'] as num?)?.toInt() ?? 0,
        branches: (json['branches'] as num?)?.toInt() ?? 0,
      );

  static const fallback = PublicStats(
    students: 5000,
    courses: 50,
    partners: 100,
    branches: 10,
  );
}

/// Model untuk kursus publik dari /api/v1/public/courses
class PublicCourse {
  final String id;
  final String name;
  final String code;
  final int price;
  final String paymentMethod;
  final String status;
  final String facilitatorName;
  final String startDate;
  final String endDate;
  final int enrollmentCount;
  final int maxParticipants;

  const PublicCourse({
    required this.id,
    required this.name,
    required this.code,
    required this.price,
    required this.paymentMethod,
    required this.status,
    required this.facilitatorName,
    required this.startDate,
    required this.endDate,
    required this.enrollmentCount,
    required this.maxParticipants,
  });

  factory PublicCourse.fromJson(Map<String, dynamic> json) => PublicCourse(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        code: json['code'] as String? ?? '',
        price: (json['price'] as num?)?.toInt() ?? 0,
        paymentMethod: json['payment_method'] as String? ?? '',
        status: json['status'] as String? ?? '',
        facilitatorName: json['facilitator_name'] as String? ?? '',
        startDate: json['start_date'] as String? ?? '',
        endDate: json['end_date'] as String? ?? '',
        enrollmentCount: (json['enrollment_count'] as num?)?.toInt() ?? 0,
        maxParticipants: (json['max_participants'] as num?)?.toInt() ?? 0,
      );

  String get priceDisplay {
    if (price == 0) return 'Gratis';
    final millions = price ~/ 1000000;
    if (millions > 0) {
      return 'Rp ${millions}jt';
    }
    final thousands = price ~/ 1000;
    return 'Rp ${thousands}k';
  }
}

/// Model untuk testimonial publik dari /api/v1/public/testimonials
class PublicTestimonial {
  final String id;
  final String studentName;
  final String quote;
  final int rating;
  final String photoUrl;
  final bool isFeatured;

  const PublicTestimonial({
    required this.id,
    required this.studentName,
    required this.quote,
    required this.rating,
    required this.photoUrl,
    required this.isFeatured,
  });

  factory PublicTestimonial.fromJson(Map<String, dynamic> json) =>
      PublicTestimonial(
        id: json['id'] as String? ?? '',
        studentName: json['student_name'] as String? ?? '',
        quote: json['quote'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 5,
        photoUrl: json['photo_url'] as String? ?? '',
        isFeatured: json['is_featured'] as bool? ?? false,
      );

  /// Inisial dari nama untuk avatar.
  String get initials {
    final parts = studentName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return studentName.isNotEmpty ? studentName[0].toUpperCase() : '?';
  }
}

/// Service untuk mengambil data dari public API VernonEdu.
/// Semua method gracefully fallback ke data default jika API tidak tersedia.
class PublicApiService {
  PublicApiService._();

  static const String _baseUrl = 'http://localhost:8081';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Ambil statistik publik.
  static Future<PublicStats> getStats() async {
    try {
      final res = await _dio.get('/api/v1/public/stats');
      final raw = res.data;
      if (raw is Map && raw['data'] != null) {
        return PublicStats.fromJson(raw['data'] as Map<String, dynamic>);
      }
      return PublicStats.fallback;
    } catch (_) {
      return PublicStats.fallback;
    }
  }

  /// Ambil daftar kursus publik (limit default 6).
  static Future<List<PublicCourse>> getCourses({int limit = 6}) async {
    try {
      final res = await _dio.get(
        '/api/v1/public/courses',
        queryParameters: {'limit': limit, 'offset': 0},
      );
      final raw = res.data;
      List list;
      if (raw is Map && raw['data'] != null) {
        final inner = raw['data'];
        if (inner is List) {
          list = inner;
        } else if (inner is Map && inner['data'] != null) {
          list = inner['data'] as List;
        } else {
          list = [];
        }
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }
      return list
          .map((e) => PublicCourse.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ambil detail batch publik via /api/v1/public/batches/{id}.
  static Future<PublicBatch?> getBatchDetail(String batchId) async {
    try {
      final res = await _dio.get('/api/v1/public/batches/$batchId');
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return PublicBatch.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Validasi kode referral. Mengembalikan nama partner jika valid, null jika tidak.
  static Future<String?> validateReferralCode(String code) async {
    try {
      final res = await _dio.get(
        '/api/v1/marketing/referral-partners',
        queryParameters: {'code': code},
      );
      final raw = res.data;
      List list;
      if (raw is Map && raw['data'] != null) {
        final inner = raw['data'];
        list = inner is List ? inner : [];
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }
      if (list.isEmpty) return null;
      final partner = list.first as Map<String, dynamic>;
      return partner['name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Submit enrollment publik via POST /api/v1/public/enrollment.
  static Future<EnrollmentResponse?> submitEnrollment(EnrollmentRequest req) async {
    try {
      final res = await _dio.post('/api/v1/public/enrollment', data: req.toJson());
      final raw = res.data;
      if (raw is Map<String, dynamic>) {
        return EnrollmentResponse.fromJson(raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ambil daftar testimonial publik.
  static Future<List<PublicTestimonial>> getTestimonials({
    int limit = 6,
    bool? isFeatured,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (isFeatured != null) params['is_featured'] = isFeatured.toString();
      final res = await _dio.get(
        '/api/v1/public/testimonials',
        queryParameters: params,
      );
      final raw = res.data;
      List list;
      if (raw is Map && raw['data'] != null) {
        final inner = raw['data'];
        list = inner is List ? inner : [];
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }
      return list
          .map((e) => PublicTestimonial.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Ambil daftar artikel/blog publik.
  static Future<(List<PublicArticle>, int)> getArticles({
    int offset = 0,
    int limit = 9,
    String? category,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{'offset': offset, 'limit': limit};
      if (category != null && category.isNotEmpty && category != 'Semua') {
        params['category'] = category;
      }
      if (search != null && search.isNotEmpty) params['search'] = search;

      final res = await _dio.get('/api/v1/public/articles', queryParameters: params);
      final raw = res.data;

      List list;
      int total = 0;
      if (raw is Map && raw['data'] != null) {
        final inner = raw['data'];
        if (inner is List) {
          list = inner;
          total = (raw['total'] as num?)?.toInt() ?? list.length;
        } else if (inner is Map && inner['data'] != null) {
          list = inner['data'] as List;
          total = (inner['total'] as num?)?.toInt() ?? list.length;
        } else {
          list = [];
        }
      } else if (raw is List) {
        list = raw;
        total = list.length;
      } else {
        list = [];
      }

      final articles = list
          .map((e) => PublicArticle.fromJson(e as Map<String, dynamic>))
          .toList();
      return (articles, total);
    } catch (_) {
      return (<PublicArticle>[], 0);
    }
  }

  /// Ambil artikel berdasarkan slug.
  static Future<PublicArticle?> getArticleBySlug(String slug) async {
    try {
      final res = await _dio.get('/api/v1/public/articles/$slug');
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return PublicArticle.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Ambil FAQ publik.
  static Future<List<PublicFaq>> getFaq({String? category}) async {
    try {
      final params = <String, dynamic>{};
      if (category != null && category.isNotEmpty) params['category'] = category;

      final res = await _dio.get('/api/v1/public/faq', queryParameters: params);
      final raw = res.data;
      List list;
      if (raw is Map && raw['data'] != null) {
        final inner = raw['data'];
        list = inner is List ? inner : [];
      } else if (raw is List) {
        list = raw;
      } else {
        list = [];
      }
      return list
          .map((e) => PublicFaq.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Submit formulir kontak publik.
  static Future<bool> submitContact({
    required String name,
    required String email,
    String? phone,
    required String category,
    required String message,
  }) async {
    try {
      await _dio.post('/api/v1/public/contact', data: {
        'name': name,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'category': category,
        'message': message,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
