import 'package:equatable/equatable.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/entities/mou_entity.dart';
import '../../domain/entities/partnership_log_entity.dart';

abstract class PartnerDetailState extends Equatable {
  const PartnerDetailState();

  @override
  List<Object?> get props => [];
}

class PartnerDetailInitial extends PartnerDetailState {
  const PartnerDetailInitial();
}

class PartnerDetailLoading extends PartnerDetailState {
  const PartnerDetailLoading();
}

class PartnerDetailLoaded extends PartnerDetailState {
  final PartnerEntity partner;
  final List<MouEntity> mous;
  final List<PartnershipLogEntity> logs;

  const PartnerDetailLoaded({
    required this.partner,
    required this.mous,
    required this.logs,
  });

  @override
  List<Object?> get props => [partner, mous, logs];
}

class PartnerDetailError extends PartnerDetailState {
  final String message;

  const PartnerDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
