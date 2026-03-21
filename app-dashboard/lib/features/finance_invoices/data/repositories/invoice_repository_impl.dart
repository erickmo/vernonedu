import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/invoice_detail_entity.dart';
import '../../domain/entities/invoice_stats_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_datasource.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const InvoiceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  String _extractError(DioException e, String fallback) {
    final msg = e.response?.data is Map
        ? (e.response!.data as Map)['error']?.toString() ?? e.message
        : e.message;
    return msg ?? fallback;
  }

  @override
  Future<Either<Failure, InvoiceStatsEntity>> getStats() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getStats();
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat statistik invoice')));
    }
  }

  @override
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
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getInvoices(
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
      return Right(result.map((e) => e.toEntity()).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat daftar invoice')));
    }
  }

  @override
  Future<Either<Failure, InvoiceDetailEntity>> getInvoiceDetail(
      String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final result = await remoteDataSource.getInvoiceDetail(id);
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat detail invoice')));
    }
  }

  @override
  Future<Either<Failure, void>> markAsPaid({
    required String id,
    required String paidAt,
    required String method,
    String? proofUrl,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.markAsPaid(
        id: id,
        paidAt: paidAt,
        method: method,
        proofUrl: proofUrl,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal menandai invoice sebagai lunas')));
    }
  }

  @override
  Future<Either<Failure, void>> resendInvoice(String id) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.resendInvoice(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal mengirim ulang invoice')));
    }
  }

  @override
  Future<Either<Failure, void>> cancelInvoice({
    required String id,
    required String reason,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.cancelInvoice(id: id, reason: reason);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal membatalkan invoice')));
    }
  }

  @override
  Future<Either<Failure, void>> createManualInvoice(
      Map<String, dynamic> body) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.createManualInvoice(body);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal membuat invoice manual')));
    }
  }
}
