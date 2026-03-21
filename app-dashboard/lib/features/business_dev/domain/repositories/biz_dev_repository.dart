import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/partner_entity.dart';
import '../entities/partner_stats_entity.dart';
import '../entities/branch_entity.dart';
import '../entities/okr_entity.dart';
import '../entities/investment_entity.dart';
import '../entities/delegation_entity.dart';

abstract class BizDevRepository {
  Future<Either<Failure, Map<String, dynamic>>> getPartners({
    int offset = 0,
    int limit = 20,
    String status = '',
  });

  Future<Either<Failure, Map<String, dynamic>>> getBranches({
    int offset = 0,
    int limit = 20,
  });

  Future<Either<Failure, List<OkrObjectiveEntity>>> getOkrObjectives({
    String level = '',
  });

  Future<Either<Failure, Map<String, dynamic>>> getInvestments({
    int offset = 0,
    int limit = 20,
    String status = '',
  });

  Future<Either<Failure, Map<String, dynamic>>> getDelegations({
    int offset = 0,
    int limit = 20,
    String status = '',
  });
}
