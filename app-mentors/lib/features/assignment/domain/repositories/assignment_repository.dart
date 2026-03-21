import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/facilitator_entity.dart';

abstract class AssignmentRepository {
  Future<Either<Failure, List<FacilitatorEntity>>> getFacilitators();
}
