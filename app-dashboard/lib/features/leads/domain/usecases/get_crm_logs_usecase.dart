import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/lead_repository.dart';
import '../entities/crm_log_entity.dart';

class GetCrmLogsUseCase {
  final LeadRepository repository;
  const GetCrmLogsUseCase(this.repository);

  Future<Either<Failure, List<CrmLogEntity>>> call(String leadId) =>
      repository.getCrmLogs(leadId);
}
