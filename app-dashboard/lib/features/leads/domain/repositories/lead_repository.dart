import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lead_entity.dart';
import '../entities/crm_log_entity.dart';

abstract class LeadRepository {
  Future<Either<Failure, List<LeadEntity>>> getLeads({
    int offset = 0,
    int limit = 50,
    String? status,
  });
  Future<Either<Failure, LeadEntity>> getLeadById(String id);
  Future<Either<Failure, LeadEntity>> createLead(Map<String, dynamic> data);
  Future<Either<Failure, LeadEntity>> updateLead(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteLead(String id);
  Future<Either<Failure, List<CrmLogEntity>>> getCrmLogs(String leadId);
  Future<Either<Failure, void>> addCrmLog(String leadId, Map<String, dynamic> data);
  Future<Either<Failure, void>> convertToStudent(String leadId);
}
