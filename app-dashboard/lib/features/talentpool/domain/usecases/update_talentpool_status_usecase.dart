import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/talentpool_repository.dart';

// Use case untuk mengupdate status talent pool (placed/inactive)
class UpdateTalentPoolStatusUseCase {
  final TalentPoolRepository _repository;
  const UpdateTalentPoolStatusUseCase(this._repository);

  Future<Either<Failure, void>> call(
          String id, String status, Map<String, dynamic>? placement) =>
      _repository.updateStatus(id, status, placement);
}
