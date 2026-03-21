import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice_detail_entity.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceListUseCase {
  final InvoiceRepository _repository;
  const GetInvoiceListUseCase(this._repository);

  Future<Either<Failure, List<InvoiceDetailEntity>>> call({
    required int offset,
    required int limit,
    String? invoiceNumber,
    String? studentName,
    String? status,
    String? batchId,
    String? paymentMethod,
    String? fromDate,
    String? toDate,
  }) =>
      _repository.getInvoices(
        offset: offset,
        limit: limit,
        invoiceNumber: invoiceNumber,
        studentName: studentName,
        status: status,
        batchId: batchId,
        paymentMethod: paymentMethod,
        fromDate: fromDate,
        toDate: toDate,
      );
}
