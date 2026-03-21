import 'package:equatable/equatable.dart';
import '../../domain/entities/marketing_stats_entity.dart';
import '../../domain/entities/social_media_post_entity.dart';
import '../../domain/entities/class_doc_post_entity.dart';
import '../../domain/entities/pr_schedule_entity.dart';
import '../../domain/entities/referral_partner_entity.dart';
import '../../domain/entities/referral_entity.dart';

abstract class MarketingState extends Equatable {
  const MarketingState();
}

class MarketingInitial extends MarketingState {
  const MarketingInitial();
  @override
  List<Object?> get props => [];
}

class MarketingLoading extends MarketingState {
  const MarketingLoading();
  @override
  List<Object?> get props => [];
}

class MarketingLoaded extends MarketingState {
  final MarketingStatsEntity stats;
  final List<SocialMediaPostEntity> posts;
  final int postsTotal;
  final List<ClassDocPostEntity> classDocs;
  final List<PrScheduleEntity> prSchedules;
  final List<ReferralPartnerEntity> referralPartners;

  const MarketingLoaded({
    required this.stats,
    required this.posts,
    this.postsTotal = 0,
    required this.classDocs,
    required this.prSchedules,
    required this.referralPartners,
  });

  @override
  List<Object?> get props =>
      [stats, posts, classDocs, prSchedules, referralPartners];
}

class MarketingReferralsLoaded extends MarketingState {
  final List<ReferralEntity> referrals;
  final String partnerId;

  const MarketingReferralsLoaded({
    required this.referrals,
    required this.partnerId,
  });

  @override
  List<Object?> get props => [referrals, partnerId];
}

class MarketingError extends MarketingState {
  final String message;
  const MarketingError(this.message);
  @override
  List<Object?> get props => [message];
}
