import '../../domain/entities/cms_article_entity.dart';

class CmsArticleModel extends CmsArticleEntity {
  const CmsArticleModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.category,
    required super.content,
    required super.featuredImage,
    required super.metaTitle,
    required super.metaDescription,
    required super.status,
    required super.authorName,
    super.publishedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CmsArticleModel.fromJson(Map<String, dynamic> json) {
    final seo = json['seo'] as Map<String, dynamic>? ?? {};
    return CmsArticleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String? ?? '',
      content: json['content'] as String? ?? '',
      featuredImage: json['featured_image'] as String? ?? '',
      metaTitle: seo['meta_title'] as String? ?? '',
      metaDescription: seo['meta_description'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      authorName: json['author_name'] as String? ?? '',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CmsArticleEntity toEntity() => CmsArticleEntity(
        id: id,
        title: title,
        slug: slug,
        category: category,
        content: content,
        featuredImage: featuredImage,
        metaTitle: metaTitle,
        metaDescription: metaDescription,
        status: status,
        authorName: authorName,
        publishedAt: publishedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
