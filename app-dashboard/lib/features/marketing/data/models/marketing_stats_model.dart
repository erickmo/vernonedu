import '../../domain/entities/marketing_stats_entity.dart';

class MarketingStatsModel extends MarketingStatsEntity {
  const MarketingStatsModel({
    required super.totalLeads,
    required super.leadsThisMonth,
    required super.leadsPrevMonth,
    required super.scheduledPosts,
    required super.postedThisMonth,
    required super.activeReferralPartners,
    required super.leadToStudentPct,
    required super.referralRevenueThisMonth,
  });

  factory MarketingStatsModel.fromJson(Map<String, dynamic> json) =>
      MarketingStatsModel(
        totalLeads: json['total_leads'] as int? ?? 0,
        leadsThisMonth: json['leads_this_month'] as int? ?? 0,
        leadsPrevMonth: json['leads_prev_month'] as int? ?? 0,
        scheduledPosts: json['scheduled_posts'] as int? ?? 0,
        postedThisMonth: json['posted_this_month'] as int? ?? 0,
        activeReferralPartners:
            json['active_referral_partners'] as int? ?? 0,
        leadToStudentPct:
            (json['lead_to_student_pct'] as num?)?.toDouble() ?? 0.0,
        referralRevenueThisMonth:
            (json['referral_revenue_this_month'] as num?)?.toDouble() ?? 0.0,
      );

  MarketingStatsEntity toEntity() => MarketingStatsEntity(
        totalLeads: totalLeads,
        leadsThisMonth: leadsThisMonth,
        leadsPrevMonth: leadsPrevMonth,
        scheduledPosts: scheduledPosts,
        postedThisMonth: postedThisMonth,
        activeReferralPartners: activeReferralPartners,
        leadToStudentPct: leadToStudentPct,
        referralRevenueThisMonth: referralRevenueThisMonth,
      );
}
