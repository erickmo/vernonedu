import '../../domain/entities/cms_page_entity.dart';

class CmsPageModel extends CmsPageEntity {
  const CmsPageModel({
    required super.slug,
    required super.title,
    required super.subtitle,
    required super.content,
    required super.heroImage,
    required super.metaTitle,
    required super.metaDescription,
    required super.ogImage,
    required super.updatedBy,
    required super.updatedAt,
  });

  factory CmsPageModel.fromJson(Map<String, dynamic> json) {
    final seo = json['seo'] as Map<String, dynamic>? ?? {};
    return CmsPageModel(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      content: json['content'] as String? ?? '',
      heroImage: json['hero_image'] as String? ?? '',
      metaTitle: seo['meta_title'] as String? ?? '',
      metaDescription: seo['meta_description'] as String? ?? '',
      ogImage: seo['og_image'] as String? ?? '',
      updatedBy: json['updated_by'] as String? ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CmsPageEntity toEntity() => CmsPageEntity(
        slug: slug,
        title: title,
        subtitle: subtitle,
        content: content,
        heroImage: heroImage,
        metaTitle: metaTitle,
        metaDescription: metaDescription,
        ogImage: ogImage,
        updatedBy: updatedBy,
        updatedAt: updatedAt,
      );
}
