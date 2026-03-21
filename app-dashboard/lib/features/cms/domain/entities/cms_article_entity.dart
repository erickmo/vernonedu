import 'package:equatable/equatable.dart';

class CmsArticleEntity extends Equatable {
  final String id;
  final String title;
  final String slug;
  final String category;
  final String content;
  final String featuredImage;
  final String metaTitle;
  final String metaDescription;
  final String status;
  final String authorName;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CmsArticleEntity({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.content,
    required this.featuredImage,
    required this.metaTitle,
    required this.metaDescription,
    required this.status,
    required this.authorName,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get categoryLabel => switch (category) {
        'tips_karir' => 'Tips Karir',
        'info_kursus' => 'Info Kursus',
        'berita' => 'Berita',
        'event' => 'Event',
        _ => category,
      };

  String get statusLabel => switch (status) {
        'draft' => 'Draft',
        'published' => 'Published',
        'archived' => 'Archived',
        _ => status,
      };

  @override
  List<Object?> get props => [id];
}
