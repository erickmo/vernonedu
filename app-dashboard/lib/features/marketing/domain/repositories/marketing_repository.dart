import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/marketing_stats_entity.dart';
import '../entities/social_media_post_entity.dart';
import '../entities/class_doc_post_entity.dart';
import '../entities/pr_schedule_entity.dart';
import '../entities/referral_partner_entity.dart';
import '../entities/referral_entity.dart';

abstract class MarketingRepository {
  Future<Either<Failure, MarketingStatsEntity>> getStats();
  Future<Either<Failure, List<SocialMediaPostEntity>>> getPosts({
    String platform,
    String status,
    String month,
  });
  Future<Either<Failure, void>> createPost(Map<String, dynamic> data);
  Future<Either<Failure, void>> updatePost(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> submitPostUrl(String id, String url);
  Future<Either<Failure, void>> deletePost(String id);
  Future<Either<Failure, List<ClassDocPostEntity>>> getClassDocs({String? status});
  Future<Either<Failure, List<PrScheduleEntity>>> getPr({
    String? status,
    String? type,
  });
  Future<Either<Failure, void>> createPr(Map<String, dynamic> data);
  Future<Either<Failure, void>> updatePr(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deletePr(String id);
  Future<Either<Failure, List<ReferralPartnerEntity>>> getReferralPartners();
  Future<Either<Failure, void>> createReferralPartner(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateReferralPartner(
      String id, Map<String, dynamic> data);
  Future<Either<Failure, List<ReferralEntity>>> getReferrals(String partnerId);
}
