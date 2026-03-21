import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/talentpool_entity.dart';
import '../entities/job_opening_entity.dart';
import '../entities/partner_company_entity.dart';

// Kontrak repository domain untuk TalentPool
abstract class TalentPoolRepository {
  Future<Either<Failure, List<TalentPoolEntity>>> getTalentPool({
    int offset = 0,
    int limit = 20,
    String status = '',
    String masterCourseId = '',
    String participantId = '',
  });
  Future<Either<Failure, TalentPoolEntity>> getTalentPoolById(String id);
  Future<Either<Failure, void>> updateStatus(
      String id, String status, Map<String, dynamic>? placement);

  Future<Either<Failure, List<JobOpeningEntity>>> getJobOpenings();
  Future<Either<Failure, List<PartnerCompanyEntity>>> getPartnerCompanies();
}
