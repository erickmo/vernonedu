import 'package:equatable/equatable.dart';
import '../../domain/entities/cms_page_entity.dart';
import '../../domain/entities/cms_article_entity.dart';
import '../../domain/entities/cms_testimonial_entity.dart';
import '../../domain/entities/cms_faq_entity.dart';
import '../../domain/entities/cms_media_entity.dart';

abstract class CmsState extends Equatable {
  const CmsState();
  @override
  List<Object?> get props => [];
}

class CmsInitial extends CmsState {
  const CmsInitial();
}

class CmsLoading extends CmsState {
  const CmsLoading();
}

class CmsError extends CmsState {
  final String message;
  const CmsError(this.message);
  @override
  List<Object?> get props => [message];
}

class CmsLoaded extends CmsState {
  final List<CmsPageEntity> pages;
  final List<CmsArticleEntity> articles;
  final int articleTotal;
  final List<CmsTestimonialEntity> testimonials;
  final List<CmsFaqEntity> faqs;
  final List<CmsMediaEntity> media;

  const CmsLoaded({
    required this.pages,
    required this.articles,
    required this.articleTotal,
    required this.testimonials,
    required this.faqs,
    required this.media,
  });

  @override
  List<Object?> get props => [pages, articles, articleTotal, testimonials, faqs, media];
}
