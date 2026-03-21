import 'package:equatable/equatable.dart';

import '../../domain/entities/talentpool_entity.dart';
import '../../domain/entities/job_opening_entity.dart';
import '../../domain/entities/partner_company_entity.dart';

abstract class TalentPoolState extends Equatable {
  const TalentPoolState();

  @override
  List<Object?> get props => [];
}

class TalentPoolInitial extends TalentPoolState {
  const TalentPoolInitial();
}

class TalentPoolLoading extends TalentPoolState {
  const TalentPoolLoading();
}

class TalentPoolLoaded extends TalentPoolState {
  final List<JobOpeningEntity> jobs;
  final List<PartnerCompanyEntity> companies;
  final List<TalentPoolEntity> members;
  final List<TalentPoolEntity> placed;
  final bool isUpdatingStatus;

  const TalentPoolLoaded({
    required this.jobs,
    required this.companies,
    required this.members,
    required this.placed,
    this.isUpdatingStatus = false,
  });

  TalentPoolLoaded copyWith({
    List<JobOpeningEntity>? jobs,
    List<PartnerCompanyEntity>? companies,
    List<TalentPoolEntity>? members,
    List<TalentPoolEntity>? placed,
    bool? isUpdatingStatus,
  }) {
    return TalentPoolLoaded(
      jobs: jobs ?? this.jobs,
      companies: companies ?? this.companies,
      members: members ?? this.members,
      placed: placed ?? this.placed,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
    );
  }

  @override
  List<Object?> get props =>
      [jobs, companies, members, placed, isUpdatingStatus];
}

class TalentPoolError extends TalentPoolState {
  final String message;
  const TalentPoolError(this.message);

  @override
  List<Object?> get props => [message];
}
