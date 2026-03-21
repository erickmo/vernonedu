import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/talentpool_entity.dart';
import '../repositories/talentpool_repository.dart';

// Use case untuk mengambil daftar talent pool dengan filter opsional
class GetTalentPoolUseCase {
  final TalentPoolRepository _repository;
  const GetTalentPoolUseCase(this._repository);

  Future<Either<Failure, List<TalentPoolEntity>>> call({
    int offset = 0,
    int limit = 20,
    String status = '',
    String masterCourseId = '',
    String participantId = '',
  }) =>
      _repository.getTalentPool(
        offset: offset,
        limit: limit,
        status: status,
        masterCourseId: masterCourseId,
        participantId: participantId,
      );
}
