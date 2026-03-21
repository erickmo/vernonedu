import 'package:equatable/equatable.dart';

class CmsPageEntity extends Equatable {
  final String slug;
  final String title;
  final String subtitle;
  final String content;
  final String heroImage;
  final String metaTitle;
  final String metaDescription;
  final String ogImage;
  final String updatedBy;
  final DateTime updatedAt;

  const CmsPageEntity({
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.heroImage,
    required this.metaTitle,
    required this.metaDescription,
    required this.ogImage,
    required this.updatedBy,
    required this.updatedAt,
  });

  int get seoScore {
    int score = 0;
    if (metaTitle.isNotEmpty) score++;
    if (metaDescription.isNotEmpty) score++;
    if (ogImage.isNotEmpty) score++;
    return (score / 3 * 100).round();
  }

  @override
  List<Object?> get props => [slug];
}
