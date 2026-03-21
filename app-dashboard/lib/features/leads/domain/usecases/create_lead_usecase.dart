import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/lead_entity.dart';
import '../repositories/lead_repository.dart';

class CreateLeadUseCase {
  final LeadRepository _repository;
  const CreateLeadUseCase(this._repository);

  Future<Either<Failure, LeadEntity>> call(Map<String, dynamic> data) =>
      _repository.createLead(data);
}
