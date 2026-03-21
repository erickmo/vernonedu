import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/lead_repository.dart';

class DeleteLeadUseCase {
  final LeadRepository _repository;
  const DeleteLeadUseCase(this._repository);

  Future<Either<Failure, void>> call(String id) => _repository.deleteLead(id);
}
