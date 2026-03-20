import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/business_entity.dart';

abstract class BusinessRepository {
  Future<Either<Failure, List<BusinessEntity>>> getBusinesses({
    int offset = 0,
    int limit = 20,
  });

  Future<Either<Failure, BusinessEntity>> getBusinessById({required String id});

  Future<Either<Failure, void>> createBusiness({required String name});

  Future<Either<Failure, void>> updateBusiness({
    required String id,
    required String name,
  });

  Future<Either<Failure, void>> deleteBusiness({required String id});
}
