import 'package:equatable/equatable.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/partner_stats_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/okr_entity.dart';
import '../../domain/entities/investment_entity.dart';
import '../../domain/entities/delegation_entity.dart';

abstract class BizDevState extends Equatable {
  const BizDevState();

  @override
  List<Object?> get props => [];
}

class BizDevInitial extends BizDevState {
  const BizDevInitial();
}

class BizDevLoading extends BizDevState {
  const BizDevLoading();
}

class BizDevLoaded extends BizDevState {
  final PartnerStatsEntity partnerStats;
  final List<PartnerEntity> partners;
  final int partnerTotal;
  final int branchActiveCount;
  final List<BranchEntity> branches;
  final List<OkrObjectiveEntity> objectives;
  final InvestmentStatsEntity investmentStats;
  final List<InvestmentPlanEntity> investments;
  final DelegationStatsEntity delegationStats;
  final List<DelegationEntity> delegations;

  const BizDevLoaded({
    required this.partnerStats,
    required this.partners,
    required this.partnerTotal,
    required this.branchActiveCount,
    required this.branches,
    required this.objectives,
    required this.investmentStats,
    required this.investments,
    required this.delegationStats,
    required this.delegations,
  });

  @override
  List<Object?> get props => [
        partnerStats,
        partners,
        partnerTotal,
        branchActiveCount,
        branches,
        objectives,
        investmentStats,
        investments,
        delegationStats,
        delegations,
      ];
}

class BizDevError extends BizDevState {
  final String message;

  const BizDevError(this.message);

  @override
  List<Object?> get props => [message];
}
