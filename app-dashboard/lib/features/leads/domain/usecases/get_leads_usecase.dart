import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lead_entity.dart';
import '../repositories/lead_repository.dart';

class GetLeadsUseCase {
  final LeadRepository _repository;
  const GetLeadsUseCase(this._repository);

  Future<Either<Failure, List<LeadEntity>>> call({
    int offset = 0,
    int limit = 50,
    String? status,
  }) =>
      _repository.getLeads(offset: offset, limit: limit, status: status);
}
