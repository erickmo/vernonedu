import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice_stats_entity.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceStatsUseCase {
  final InvoiceRepository _repository;
  const GetInvoiceStatsUseCase(this._repository);

  Future<Either<Failure, InvoiceStatsEntity>> call() =>
      _repository.getStats();
}
