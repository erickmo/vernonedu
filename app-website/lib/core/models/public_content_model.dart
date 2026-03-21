/// Models for /api/v1/public/pages, articles, testimonials, faq, stats

class SiteStats {
  final int studentCount;
  final int courseCount;
  final int batchCount;
  final int partnerCount;
  final int graduateCount;
  final double satisfactionRate;

  const SiteStats({
    required this.studentCount,
    required this.courseCount,
    required this.batchCount,
    required this.partnerCount,
    required this.graduateCount,
    required this.satisfactionRate,
  });

  factory SiteStats.fromJson(Map<String, dynamic> json) => SiteStats(
        studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
        courseCount: (json['course_count'] as num?)?.toInt() ?? 0,
        batchCount: (json['batch_count'] as num?)?.toInt() ?? 0,
        partnerCount: (json['partner_count'] as num?)?.toInt() ?? 0,
        graduateCount: (json['graduate_count'] as num?)?.toInt() ?? 0,
        satisfactionRate:
            (json['satisfaction_rate'] as num?)?.toDouble() ?? 0.0,
      );
}

class PageSeo {
  final String title;
  final String description;
  final String? ogImage;

  const PageSeo({
    required this.title,
    required this.description,
    this.ogImage,
  });

  factory PageSeo.fromJson(Map<String, dynamic> json) => PageSeo(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        ogImage: json['og_image'] as String?,
      );
}

class PageContent {
  final String slug;
  final String title;
  final String subtitle;
  final Map<String, dynamic> content;
  final PageSeo? seo;

  const PageContent({
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.content,
    this.seo,
  });

  factory PageContent.fromJson(Map<String, dynamic> json) {
    final seoJson = json['seo'];
    final contentJson = json['content'];
    return PageContent(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      content: contentJson is Map<String, dynamic> ? contentJson : {},
      seo: seoJson != null
          ? PageSeo.fromJson(seoJson as Map<String, dynamic>)
          : null,
    );
  }
}

class Article {
  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String category;
  final String status;
  final String? thumbnailUrl;
  final String? authorName;
  final String publishedAt;
  final String content;

  const Article({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.category,
    required this.status,
    this.thumbnailUrl,
    this.authorName,
    required this.publishedAt,
    required this.content,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        excerpt: json['excerpt'] as String? ?? '',
        category: json['category'] as String? ?? '',
        status: json['status'] as String? ?? '',
        thumbnailUrl: json['thumbnail_url'] as String?,
        authorName: json['author_name'] as String?,
        publishedAt: json['published_at'] as String? ?? '',
        content: json['content'] as String? ?? '',
      );
}

class ArticleListResult {
  final List<Article> data;
  final int total;

  const ArticleListResult({required this.data, required this.total});

  factory ArticleListResult.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] as List? ?? [];
    return ArticleListResult(
      data: raw
          .map((e) => Article.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class Testimonial {
  final String id;
  final String studentName;
  final String? avatarUrl;
  final String courseName;
  final String content;
  final int rating;
  final bool isFeatured;

  const Testimonial({
    required this.id,
    required this.studentName,
    this.avatarUrl,
    required this.courseName,
    required this.content,
    required this.rating,
    required this.isFeatured,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) => Testimonial(
        id: json['id'] as String? ?? '',
        studentName: json['student_name'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        courseName: json['course_name'] as String? ?? '',
        content: json['content'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 5,
        isFeatured: json['is_featured'] as bool? ?? false,
      );
}

class FaqItem {
  final String id;
  final String question;
  final String answer;
  final String category;
  final String? pageSlug;
  final int sortOrder;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.pageSlug,
    required this.sortOrder,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
        id: json['id'] as String? ?? '',
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
        category: json['category'] as String? ?? '',
        pageSlug: json['page_slug'] as String?,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}
