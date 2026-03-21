import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_cms_pages_usecase.dart';
import '../../domain/usecases/update_cms_page_usecase.dart';
import '../../domain/usecases/get_cms_articles_usecase.dart';
import '../../domain/usecases/create_cms_article_usecase.dart';
import '../../domain/usecases/update_cms_article_usecase.dart';
import '../../domain/usecases/delete_cms_article_usecase.dart';
import '../../domain/usecases/get_cms_testimonials_usecase.dart';
import '../../domain/usecases/create_cms_testimonial_usecase.dart';
import '../../domain/usecases/update_cms_testimonial_usecase.dart';
import '../../domain/usecases/delete_cms_testimonial_usecase.dart';
import '../../domain/usecases/get_cms_faq_usecase.dart';
import '../../domain/usecases/create_cms_faq_usecase.dart';
import '../../domain/usecases/update_cms_faq_usecase.dart';
import '../../domain/usecases/delete_cms_faq_usecase.dart';
import '../../domain/usecases/get_cms_media_usecase.dart';
import '../../domain/usecases/delete_cms_media_usecase.dart';
import '../../domain/entities/cms_page_entity.dart';
import '../../domain/entities/cms_article_entity.dart';
import '../../domain/entities/cms_testimonial_entity.dart';
import '../../domain/entities/cms_faq_entity.dart';
import '../../domain/entities/cms_media_entity.dart';
import 'cms_state.dart';

class CmsCubit extends Cubit<CmsState> {
  final GetCmsPagesUseCase _getPages;
  final UpdateCmsPageUseCase _updatePage;
  final GetCmsArticlesUseCase _getArticles;
  final CreateCmsArticleUseCase _createArticle;
  final UpdateCmsArticleUseCase _updateArticle;
  final DeleteCmsArticleUseCase _deleteArticle;
  final GetCmsTestimonialsUseCase _getTestimonials;
  final CreateCmsTestimonialUseCase _createTestimonial;
  final UpdateCmsTestimonialUseCase _updateTestimonial;
  final DeleteCmsTestimonialUseCase _deleteTestimonial;
  final GetCmsFaqUseCase _getFaq;
  final CreateCmsFaqUseCase _createFaq;
  final UpdateCmsFaqUseCase _updateFaq;
  final DeleteCmsFaqUseCase _deleteFaq;
  final GetCmsMediaUseCase _getMedia;
  final DeleteCmsMediaUseCase _deleteMedia;

  CmsCubit({
    required GetCmsPagesUseCase getPages,
    required UpdateCmsPageUseCase updatePage,
    required GetCmsArticlesUseCase getArticles,
    required CreateCmsArticleUseCase createArticle,
    required UpdateCmsArticleUseCase updateArticle,
    required DeleteCmsArticleUseCase deleteArticle,
    required GetCmsTestimonialsUseCase getTestimonials,
    required CreateCmsTestimonialUseCase createTestimonial,
    required UpdateCmsTestimonialUseCase updateTestimonial,
    required DeleteCmsTestimonialUseCase deleteTestimonial,
    required GetCmsFaqUseCase getFaq,
    required CreateCmsFaqUseCase createFaq,
    required UpdateCmsFaqUseCase updateFaq,
    required DeleteCmsFaqUseCase deleteFaq,
    required GetCmsMediaUseCase getMedia,
    required DeleteCmsMediaUseCase deleteMedia,
  })  : _getPages = getPages,
        _updatePage = updatePage,
        _getArticles = getArticles,
        _createArticle = createArticle,
        _updateArticle = updateArticle,
        _deleteArticle = deleteArticle,
        _getTestimonials = getTestimonials,
        _createTestimonial = createTestimonial,
        _updateTestimonial = updateTestimonial,
        _deleteTestimonial = deleteTestimonial,
        _getFaq = getFaq,
        _createFaq = createFaq,
        _updateFaq = updateFaq,
        _deleteFaq = deleteFaq,
        _getMedia = getMedia,
        _deleteMedia = deleteMedia,
        super(const CmsInitial());

  Future<void> loadAll() async {
    emit(const CmsLoading());

    final results = await Future.wait([
      _getPages(),
      _getArticles(offset: 0, limit: 15),
      _getTestimonials(),
      _getFaq(),
      _getMedia(),
    ]);

    String? errorMessage;

    List<CmsPageEntity> pages = [];
    results[0].fold((f) => errorMessage = f.message, (data) {
      pages = data as List<CmsPageEntity>;
    });
    if (errorMessage != null) { emit(CmsError(errorMessage!)); return; }

    List<CmsArticleEntity> articles = [];
    int articleTotal = 0;
    results[1].fold((f) => errorMessage = f.message, (data) {
      final map = data as Map<String, dynamic>;
      articles = (map['data'] as List?)?.cast<CmsArticleEntity>() ?? [];
      articleTotal = (map['total'] as int?) ?? 0;
    });
    if (errorMessage != null) { emit(CmsError(errorMessage!)); return; }

    List<CmsTestimonialEntity> testimonials = [];
    results[2].fold((f) => errorMessage = f.message, (data) {
      testimonials = data as List<CmsTestimonialEntity>;
    });
    if (errorMessage != null) { emit(CmsError(errorMessage!)); return; }

    List<CmsFaqEntity> faqs = [];
    results[3].fold((f) => errorMessage = f.message, (data) {
      faqs = data as List<CmsFaqEntity>;
    });
    if (errorMessage != null) { emit(CmsError(errorMessage!)); return; }

    List<CmsMediaEntity> media = [];
    results[4].fold((f) => errorMessage = f.message, (data) {
      media = data as List<CmsMediaEntity>;
    });
    if (errorMessage != null) { emit(CmsError(errorMessage!)); return; }

    emit(CmsLoaded(
      pages: pages,
      articles: articles,
      articleTotal: articleTotal,
      testimonials: testimonials,
      faqs: faqs,
      media: media,
    ));
  }

  Future<void> savePage(String slug, Map<String, dynamic> data) async {
    await _updatePage(slug, data);
    await loadAll();
  }

  Future<void> createArticle(Map<String, dynamic> data) async {
    await _createArticle(data);
    await loadAll();
  }

  Future<void> updateArticle(String id, Map<String, dynamic> data) async {
    await _updateArticle(id, data);
    await loadAll();
  }

  Future<void> deleteArticle(String id) async {
    await _deleteArticle(id);
    await loadAll();
  }

  Future<void> createTestimonial(Map<String, dynamic> data) async {
    await _createTestimonial(data);
    await loadAll();
  }

  Future<void> updateTestimonial(String id, Map<String, dynamic> data) async {
    await _updateTestimonial(id, data);
    await loadAll();
  }

  Future<void> deleteTestimonial(String id) async {
    await _deleteTestimonial(id);
    await loadAll();
  }

  Future<void> createFaq(Map<String, dynamic> data) async {
    await _createFaq(data);
    await loadAll();
  }

  Future<void> updateFaq(String id, Map<String, dynamic> data) async {
    await _updateFaq(id, data);
    await loadAll();
  }

  Future<void> deleteFaq(String id) async {
    await _deleteFaq(id);
    await loadAll();
  }

  Future<void> deleteMedia(String id) async {
    await _deleteMedia(id);
    await loadAll();
  }
}
