import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/partner_stats_entity.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/investment_entity.dart';
import '../../domain/entities/delegation_entity.dart';
import '../../domain/usecases/get_partners_usecase.dart';
import '../../domain/usecases/get_branches_usecase.dart';
import '../../domain/usecases/get_okr_usecase.dart';
import '../../domain/usecases/get_investments_usecase.dart';
import '../../domain/usecases/get_delegations_usecase.dart';
import '../../data/models/partner_model.dart';
import '../../data/models/branch_model.dart';
import '../../data/models/investment_model.dart';
import '../../data/models/delegation_model.dart';
import 'biz_dev_state.dart';

class BizDevCubit extends Cubit<BizDevState> {
  final GetPartnersUseCase _getPartners;
  final GetBranchesUseCase _getBranches;
  final GetOkrUseCase _getOkr;
  final GetInvestmentsUseCase _getInvestments;
  final GetDelegationsUseCase _getDelegations;

  BizDevCubit({
    required GetPartnersUseCase getPartners,
    required GetBranchesUseCase getBranches,
    required GetOkrUseCase getOkr,
    required GetInvestmentsUseCase getInvestments,
    required GetDelegationsUseCase getDelegations,
  })  : _getPartners = getPartners,
        _getBranches = getBranches,
        _getOkr = getOkr,
        _getInvestments = getInvestments,
        _getDelegations = getDelegations,
        super(const BizDevInitial());

  Future<void> loadAll() async {
    emit(const BizDevLoading());

    final results = await Future.wait([
      _getPartners(offset: 0, limit: 50),
      _getBranches(offset: 0, limit: 100),
      _getOkr(),
      _getInvestments(offset: 0, limit: 50),
      _getDelegations(offset: 0, limit: 50),
    ]);

    String? errorMessage;

    // Parse partners
    List<PartnerEntity> partners = [];
    PartnerStatsEntity partnerStats = const PartnerStatsEntity(
      activeCount: 0,
      expiringCount: 0,
      negotiatingCount: 0,
      uncontactedCount: 0,
    );
    int partnerTotal = 0;
    results[0].fold(
      (f) => errorMessage = f.message,
      (data) {
        if (data is Map<String, dynamic>) {
          final raw = data['data'] as List? ?? [];
          partners = raw
              .map((e) => PartnerModel.fromJson(e as Map<String, dynamic>)
                  .toEntity())
              .toList();
          partnerTotal = (data['total'] as num?)?.toInt() ?? partners.length;
          final statsMap = data['stats'] as Map<String, dynamic>?;
          if (statsMap != null) {
            partnerStats = PartnerStatsEntity(
              activeCount:
                  (statsMap['active_count'] as num?)?.toInt() ?? 0,
              expiringCount:
                  (statsMap['expiring_count'] as num?)?.toInt() ?? 0,
              negotiatingCount:
                  (statsMap['negotiating_count'] as num?)?.toInt() ?? 0,
              uncontactedCount:
                  (statsMap['uncontacted_count'] as num?)?.toInt() ?? 0,
            );
          }
        }
      },
    );
    if (errorMessage != null) {
      emit(BizDevError(errorMessage!));
      return;
    }

    // Parse branches
    List<BranchEntity> branches = [];
    int branchActiveCount = 0;
    results[1].fold(
      (f) => errorMessage = f.message,
      (data) {
        if (data is Map<String, dynamic>) {
          final raw = data['data'] as List? ?? [];
          branches = raw
              .map((e) =>
                  BranchModel.fromJson(e as Map<String, dynamic>).toEntity())
              .toList();
          branchActiveCount = branches.where((b) => b.isActive).length;
        }
      },
    );
    if (errorMessage != null) {
      emit(BizDevError(errorMessage!));
      return;
    }

    // Parse OKR
    final okrResult = results[2];
    final objectives = okrResult.fold(
      (f) {
        errorMessage = f.message;
        return [];
      },
      (data) => data,
    );
    if (errorMessage != null) {
      emit(BizDevError(errorMessage!));
      return;
    }

    // Parse investments
    List<InvestmentPlanEntity> investments = [];
    InvestmentStatsEntity investmentStats = const InvestmentStatsEntity(
      totalPlanned: 0,
      ongoingCount: 0,
      ongoingAmount: 0,
      completedCount: 0,
      completedAmount: 0,
      avgRoi: 0,
    );
    results[3].fold(
      (f) => errorMessage = f.message,
      (data) {
        if (data is Map<String, dynamic>) {
          final raw = data['data'] as List? ?? [];
          investments = raw
              .map((e) => InvestmentPlanModel.fromJson(
                      e as Map<String, dynamic>)
                  .toEntity())
              .toList();
          final statsMap = data['stats'] as Map<String, dynamic>?;
          if (statsMap != null) {
            investmentStats = InvestmentStatsModel.fromJson(statsMap).toEntity();
          }
        }
      },
    );
    if (errorMessage != null) {
      emit(BizDevError(errorMessage!));
      return;
    }

    // Parse delegations
    List<DelegationEntity> delegations = [];
    DelegationStatsEntity delegationStats = const DelegationStatsEntity(
      activeCount: 0,
      pendingCount: 0,
      inProgressCount: 0,
      completedThisMonthCount: 0,
    );
    results[4].fold(
      (f) => errorMessage = f.message,
      (data) {
        if (data is Map<String, dynamic>) {
          final raw = data['data'] as List? ?? [];
          delegations = raw
              .map((e) =>
                  DelegationModel.fromJson(e as Map<String, dynamic>).toEntity())
              .toList();
          final statsMap = data['stats'] as Map<String, dynamic>?;
          if (statsMap != null) {
            delegationStats =
                DelegationStatsModel.fromJson(statsMap).toEntity();
          }
        }
      },
    );
    if (errorMessage != null) {
      emit(BizDevError(errorMessage!));
      return;
    }

    emit(BizDevLoaded(
      partnerStats: partnerStats,
      partners: partners,
      partnerTotal: partnerTotal,
      branchActiveCount: branchActiveCount,
      branches: branches,
      objectives: objectives,
      investmentStats: investmentStats,
      investments: investments,
      delegationStats: delegationStats,
      delegations: delegations,
    ));
  }
}
