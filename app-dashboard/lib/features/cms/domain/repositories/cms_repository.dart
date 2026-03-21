import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/cms_page_entity.dart';
import '../entities/cms_article_entity.dart';
import '../entities/cms_testimonial_entity.dart';
import '../entities/cms_faq_entity.dart';
import '../entities/cms_media_entity.dart';

abstract class CmsRepository {
  Future<Either<Failure, List<CmsPageEntity>>> getPages();
  Future<Either<Failure, CmsPageEntity>> getPage(String slug);
  Future<Either<Failure, void>> updatePage(String slug, Map<String, dynamic> data);
  Future<Either<Failure, Map<String, dynamic>>> getArticles({
    int offset = 0,
    int limit = 15,
    String? category,
    String? status,
  });
  Future<Either<Failure, void>> createArticle(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateArticle(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteArticle(String id);
  Future<Either<Failure, List<CmsTestimonialEntity>>> getTestimonials();
  Future<Either<Failure, void>> createTestimonial(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateTestimonial(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteTestimonial(String id);
  Future<Either<Failure, List<CmsFaqEntity>>> getFaq({String? category});
  Future<Either<Failure, void>> createFaq(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateFaq(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteFaq(String id);
  Future<Either<Failure, List<CmsMediaEntity>>> getMedia();
  Future<Either<Failure, void>> deleteMedia(String id);
}
