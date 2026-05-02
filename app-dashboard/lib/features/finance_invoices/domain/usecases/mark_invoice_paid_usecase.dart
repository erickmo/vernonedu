import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/invoice_repository.dart';

class MarkInvoicePaidUseCase {
  final InvoiceRepository _repository;
  const MarkInvoicePaidUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String id,
    required String paidAt,
    double? paidAmount,
    String? paymentProof,
    String? accountCode,
  }) =>
      _repository.markAsPaid(
        id: id,
        paidAt: paidAt,
        paidAmount: paidAmount,
        paymentProof: paymentProof,
        accountCode: accountCode,
      );
}
