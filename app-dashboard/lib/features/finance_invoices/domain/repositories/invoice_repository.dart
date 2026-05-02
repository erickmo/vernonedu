import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/invoice_detail_entity.dart';
import '../entities/invoice_stats_entity.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, InvoiceStatsEntity>> getStats();

  Future<Either<Failure, List<InvoiceDetailEntity>>> getInvoices({
    required int offset,
    required int limit,
    String? invoiceNumber,
    String? studentName,
    String? status,
    String? batchId,
    String? paymentMethod,
    String? fromDate,
    String? toDate,
  });

  Future<Either<Failure, InvoiceDetailEntity>> getInvoiceDetail(String id);

  Future<Either<Failure, void>> markAsPaid({
    required String id,
    required String paidAt,
    double? paidAmount,
    String? paymentProof,
    String? accountCode,
  });

  Future<Either<Failure, void>> sendInvoice(String id);

  Future<Either<Failure, void>> cancelInvoice({
    required String id,
    required String reason,
  });

  Future<Either<Failure, void>> createManualInvoice(Map<String, dynamic> body);
}
