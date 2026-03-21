import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice_entity.dart';
import '../repositories/accounting_repository.dart';

class GetInvoicesUseCase {
  final AccountingRepository _repository;
  const GetInvoicesUseCase(this._repository);

  Future<Either<Failure, List<InvoiceEntity>>> call({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? status,
  }) =>
      _repository.getInvoices(
        offset: offset,
        limit: limit,
        month: month,
        year: year,
        status: status,
      );
}
