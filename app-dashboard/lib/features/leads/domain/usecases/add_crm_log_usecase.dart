import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/lead_repository.dart';

class AddCrmLogUseCase {
  final LeadRepository repository;
  const AddCrmLogUseCase(this.repository);

  Future<Either<Failure, void>> call(String leadId, Map<String, dynamic> data) =>
      repository.addCrmLog(leadId, data);
}
