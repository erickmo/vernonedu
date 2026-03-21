import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/talentpool_entity.dart';
import '../../domain/entities/job_opening_entity.dart';
import '../../domain/entities/partner_company_entity.dart';
import '../../domain/usecases/get_talentpool_usecase.dart';
import '../../domain/usecases/update_talentpool_status_usecase.dart';
import '../../domain/usecases/get_job_openings_usecase.dart';
import '../../domain/usecases/get_partner_companies_usecase.dart';
import 'talentpool_state.dart';

class TalentPoolCubit extends Cubit<TalentPoolState> {
  final GetTalentPoolUseCase getTalentPoolUseCase;
  final UpdateTalentPoolStatusUseCase updateTalentPoolStatusUseCase;
  final GetJobOpeningsUseCase getJobOpeningsUseCase;
  final GetPartnerCompaniesUseCase getPartnerCompaniesUseCase;

  TalentPoolCubit({
    required this.getTalentPoolUseCase,
    required this.updateTalentPoolStatusUseCase,
    required this.getJobOpeningsUseCase,
    required this.getPartnerCompaniesUseCase,
  }) : super(const TalentPoolInitial());

  Future<void> loadAll() async {
    emit(const TalentPoolLoading());

    final results = await Future.wait([
      getJobOpeningsUseCase(),
      getPartnerCompaniesUseCase(),
      getTalentPoolUseCase(limit: 200),
    ]);

    final jobs = results[0].fold<List<JobOpeningEntity>>(
      (_) => [],
      (data) => data as List<JobOpeningEntity>,
    );
    final companies = results[1].fold<List<PartnerCompanyEntity>>(
      (_) => [],
      (data) => data as List<PartnerCompanyEntity>,
    );
    final allMembers = results[2].fold<List<TalentPoolEntity>>(
      (failure) {
        emit(TalentPoolError(failure.message));
        return [];
      },
      (data) => data as List<TalentPoolEntity>,
    );

    if (state is TalentPoolError) return;

    emit(TalentPoolLoaded(
      jobs: jobs,
      companies: companies,
      members: allMembers.where((t) => !t.isPlaced).toList(),
      placed: allMembers.where((t) => t.isPlaced).toList(),
    ));
  }

  Future<bool> updateStatus(
      String id, String status, Map<String, dynamic>? placement) async {
    final current = state;
    if (current is! TalentPoolLoaded) return false;

    emit(current.copyWith(isUpdatingStatus: true));

    final result = await updateTalentPoolStatusUseCase(id, status, placement);
    return result.fold(
      (failure) {
        emit(current.copyWith(isUpdatingStatus: false));
        return false;
      },
      (_) {
        loadAll();
        return true;
      },
    );
  }
}
