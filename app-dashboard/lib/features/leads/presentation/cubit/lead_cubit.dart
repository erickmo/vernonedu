import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/crm_log_entity.dart';
import '../../domain/usecases/get_leads_usecase.dart';
import '../../domain/usecases/create_lead_usecase.dart';
import '../../domain/usecases/update_lead_usecase.dart';
import '../../domain/usecases/delete_lead_usecase.dart';
import '../../domain/usecases/get_crm_logs_usecase.dart';
import '../../domain/usecases/add_crm_log_usecase.dart';
import '../../domain/usecases/convert_lead_usecase.dart';
import 'lead_state.dart';

class LeadCubit extends Cubit<LeadState> {
  final GetLeadsUseCase getLeadsUseCase;
  final CreateLeadUseCase createLeadUseCase;
  final UpdateLeadUseCase updateLeadUseCase;
  final DeleteLeadUseCase deleteLeadUseCase;
  final GetCrmLogsUseCase getCrmLogsUseCase;
  final AddCrmLogUseCase addCrmLogUseCase;
  final ConvertLeadUseCase convertLeadUseCase;

  LeadCubit({
    required this.getLeadsUseCase,
    required this.createLeadUseCase,
    required this.updateLeadUseCase,
    required this.deleteLeadUseCase,
    required this.getCrmLogsUseCase,
    required this.addCrmLogUseCase,
    required this.convertLeadUseCase,
  }) : super(const LeadInitial());

  Future<void> loadLeads({
    int offset = 0,
    int limit = 50,
    String? status,
  }) async {
    emit(const LeadLoading());
    final result = await getLeadsUseCase(offset: offset, limit: limit, status: status);
    result.fold(
      (failure) => emit(LeadError(failure.message)),
      (leads) => emit(LeadLoaded(leads: leads, total: leads.length)),
    );
  }

  Future<bool> createLead(Map<String, dynamic> data) async {
    final result = await createLeadUseCase(data);
    return result.fold(
      (failure) {
        emit(LeadError(failure.message));
        return false;
      },
      (_) {
        loadLeads();
        return true;
      },
    );
  }

  Future<bool> updateLead(String id, Map<String, dynamic> data) async {
    final result = await updateLeadUseCase(id, data);
    return result.fold(
      (failure) {
        emit(LeadError(failure.message));
        return false;
      },
      (_) {
        loadLeads();
        return true;
      },
    );
  }

  Future<bool> deleteLead(String id) async {
    final result = await deleteLeadUseCase(id);
    return result.fold(
      (failure) {
        emit(LeadError(failure.message));
        return false;
      },
      (_) {
        loadLeads();
        return true;
      },
    );
  }

  Future<List<CrmLogEntity>> getCrmLogs(String leadId) async {
    final result = await getCrmLogsUseCase(leadId);
    return result.fold((_) => [], (logs) => logs);
  }

  Future<bool> addCrmLog(String leadId, Map<String, dynamic> data) async {
    final result = await addCrmLogUseCase(leadId, data);
    return result.fold(
      (failure) {
        emit(LeadError(failure.message));
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> convertToStudent(String leadId) async {
    final result = await convertLeadUseCase(leadId);
    return result.fold(
      (failure) {
        emit(LeadError(failure.message));
        return false;
      },
      (_) {
        loadLeads();
        return true;
      },
    );
  }
}
