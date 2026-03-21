import 'package:equatable/equatable.dart';

class MarketingStatsEntity extends Equatable {
  final int totalLeads;
  final int leadsThisMonth;
  final int leadsPrevMonth;
  final int scheduledPosts;
  final int postedThisMonth;
  final int activeReferralPartners;
  final double leadToStudentPct;
  final double referralRevenueThisMonth;

  const MarketingStatsEntity({
    required this.totalLeads,
    required this.leadsThisMonth,
    required this.leadsPrevMonth,
    required this.scheduledPosts,
    required this.postedThisMonth,
    required this.activeReferralPartners,
    required this.leadToStudentPct,
    required this.referralRevenueThisMonth,
  });

  @override
  List<Object?> get props => [
        totalLeads,
        leadsThisMonth,
        leadsPrevMonth,
        scheduledPosts,
        postedThisMonth,
        activeReferralPartners,
        leadToStudentPct,
        referralRevenueThisMonth,
      ];
}
