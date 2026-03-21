import 'package:equatable/equatable.dart';
import '../../domain/entities/lead_entity.dart';
import '../../domain/entities/crm_log_entity.dart';

abstract class LeadState extends Equatable {
  const LeadState();
  @override
  List<Object?> get props => [];
}

class LeadInitial extends LeadState {
  const LeadInitial();
}

class LeadLoading extends LeadState {
  const LeadLoading();
}

class LeadLoaded extends LeadState {
  final List<LeadEntity> leads;
  final int total;

  const LeadLoaded({required this.leads, required this.total});

  @override
  List<Object?> get props => [leads, total];
}

class LeadError extends LeadState {
  final String message;

  const LeadError(this.message);

  @override
  List<Object?> get props => [message];
}

class LeadCrmLogsLoaded extends LeadState {
  final List<CrmLogEntity> logs;
  final String leadId;

  const LeadCrmLogsLoaded({required this.logs, required this.leadId});

  @override
  List<Object?> get props => [logs, leadId];
}
