import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/lead_repository.dart';

class ConvertLeadUseCase {
  final LeadRepository repository;
  const ConvertLeadUseCase(this.repository);

  Future<Either<Failure, void>> call(String leadId) =>
      repository.convertToStudent(leadId);
}
