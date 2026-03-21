import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lead_entity.dart';
import '../repositories/lead_repository.dart';

class UpdateLeadUseCase {
  final LeadRepository _repository;
  const UpdateLeadUseCase(this._repository);

  Future<Either<Failure, LeadEntity>> call(String id, Map<String, dynamic> data) =>
      _repository.updateLead(id, data);
}
