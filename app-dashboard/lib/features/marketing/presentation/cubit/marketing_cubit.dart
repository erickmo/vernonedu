import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/marketing_stats_entity.dart';
import '../../domain/entities/social_media_post_entity.dart';
import '../../domain/entities/class_doc_post_entity.dart';
import '../../domain/entities/pr_schedule_entity.dart';
import '../../domain/entities/referral_partner_entity.dart';
import '../../domain/usecases/get_marketing_stats_usecase.dart';
import '../../domain/usecases/get_posts_usecase.dart';
import '../../domain/usecases/create_post_usecase.dart';
import '../../domain/usecases/update_post_usecase.dart';
import '../../domain/usecases/submit_post_url_usecase.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_class_docs_usecase.dart';
import '../../domain/usecases/get_pr_usecase.dart';
import '../../domain/usecases/create_pr_usecase.dart';
import '../../domain/usecases/update_pr_usecase.dart';
import '../../domain/usecases/delete_pr_usecase.dart';
import '../../domain/usecases/get_referral_partners_usecase.dart';
import '../../domain/usecases/create_referral_partner_usecase.dart';
import '../../domain/usecases/update_referral_partner_usecase.dart';
import '../../domain/usecases/get_referrals_usecase.dart';
import 'marketing_state.dart';

class MarketingCubit extends Cubit<MarketingState> {
  final GetMarketingStatsUseCase getStatsUseCase;
  final GetPostsUseCase getPostsUseCase;
  final CreatePostUseCase createPostUseCase;
  final UpdatePostUseCase updatePostUseCase;
  final SubmitPostUrlUseCase submitPostUrlUseCase;
  final DeletePostUseCase deletePostUseCase;
  final GetClassDocsUseCase getClassDocsUseCase;
  final GetPrUseCase getPrUseCase;
  final CreatePrUseCase createPrUseCase;
  final UpdatePrUseCase updatePrUseCase;
  final DeletePrUseCase deletePrUseCase;
  final GetReferralPartnersUseCase getReferralPartnersUseCase;
  final CreateReferralPartnerUseCase createReferralPartnerUseCase;
  final UpdateReferralPartnerUseCase updateReferralPartnerUseCase;
  final GetReferralsUseCase getReferralsUseCase;

  MarketingCubit({
    required this.getStatsUseCase,
    required this.getPostsUseCase,
    required this.createPostUseCase,
    required this.updatePostUseCase,
    required this.submitPostUrlUseCase,
    required this.deletePostUseCase,
    required this.getClassDocsUseCase,
    required this.getPrUseCase,
    required this.createPrUseCase,
    required this.updatePrUseCase,
    required this.deletePrUseCase,
    required this.getReferralPartnersUseCase,
    required this.createReferralPartnerUseCase,
    required this.updateReferralPartnerUseCase,
    required this.getReferralsUseCase,
  }) : super(const MarketingInitial());

  Future<void> loadAll() async {
    emit(const MarketingLoading());
    final results = await Future.wait([
      getStatsUseCase(),
      getPostsUseCase(),
      getClassDocsUseCase(),
      getPrUseCase(),
      getReferralPartnersUseCase(),
    ]);

    MarketingStatsEntity? stats;
    results[0].fold(
      (f) => emit(MarketingError(f.message)),
      (v) => stats = v as MarketingStatsEntity,
    );
    if (state is MarketingError) return;

    final posts = results[1].fold(
      (_) => <SocialMediaPostEntity>[],
      (v) => v as List<SocialMediaPostEntity>,
    );
    final classDocs = results[2].fold(
      (_) => <ClassDocPostEntity>[],
      (v) => v as List<ClassDocPostEntity>,
    );
    final prSchedules = results[3].fold(
      (_) => <PrScheduleEntity>[],
      (v) => v as List<PrScheduleEntity>,
    );
    final partners = results[4].fold(
      (_) => <ReferralPartnerEntity>[],
      (v) => v as List<ReferralPartnerEntity>,
    );

    emit(MarketingLoaded(
      stats: stats!,
      posts: posts,
      classDocs: classDocs,
      prSchedules: prSchedules,
      referralPartners: partners,
    ));
  }

  Future<bool> createPost(Map<String, dynamic> data) async {
    final result = await createPostUseCase(data);
    return result.fold(
      (f) {
        emit(MarketingError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<bool> updatePost(String id, Map<String, dynamic> data) async {
    final result = await updatePostUseCase(id, data);
    return result.fold(
      (f) {
        emit(MarketingError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<bool> submitPostUrl(String id, String url) async {
    final result = await submitPostUrlUseCase(id, url);
    return result.fold(
      (f) {
        emit(MarketingError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<bool> deletePost(String id) async {
    final result = await deletePostUseCase(id);
    return result.fold(
      (f) {
        emit(MarketingError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<bool> createPr(Map<String, dynamic> data) async {
    final result = await createPrUseCase(data);
    return result.fold(
      (f) {
        emit(MarketingError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<bool> updatePr(String id, Map<String, dynamic> data) async {
    final result = await updatePrUseCase(id, data);
    return result.fold(
      (f) {
        emit(MarketingError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<bool> deletePr(String id) async {
    final result = await deletePrUseCase(id);
    return result.fold(
      (f) {
        emit(MarketingError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<bool> createReferralPartner(Map<String, dynamic> data) async {
    final result = await createReferralPartnerUseCase(data);
    return result.fold(
      (f) {
        emit(MarketingError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<bool> updateReferralPartner(
      String id, Map<String, dynamic> data) async {
    final result = await updateReferralPartnerUseCase(id, data);
    return result.fold(
      (f) {
        emit(MarketingError(f.message));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }

  Future<void> loadReferrals(String partnerId) async {
    final result = await getReferralsUseCase(partnerId);
    result.fold(
      (f) => emit(MarketingError(f.message)),
      (referrals) => emit(
        MarketingReferralsLoaded(referrals: referrals, partnerId: partnerId),
      ),
    );
  }
}
