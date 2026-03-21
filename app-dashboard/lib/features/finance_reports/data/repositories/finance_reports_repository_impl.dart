import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/balance_sheet_entity.dart';
import '../../domain/entities/cash_flow_entity.dart';
import '../../domain/entities/ledger_entity.dart';
import '../../domain/entities/profit_loss_entity.dart';
import '../../domain/entities/report_filter_entity.dart';
import '../../domain/entities/trial_balance_entity.dart';
import '../../domain/repositories/finance_reports_repository.dart';
import '../datasources/finance_reports_remote_datasource.dart';

class FinanceReportsRepositoryImpl implements FinanceReportsRepository {
  final FinanceReportsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const FinanceReportsRepositoryImpl({
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
  Future<Either<Failure, BalanceSheetEntity>> getBalanceSheet(
      ReportFilterEntity filter) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final params = filter.toQueryParams();
      final result = await remoteDataSource.getBalanceSheet(
        period: params['period'] as String,
        branchId: params['branch_id'] as String?,
        fromDate: params['from_date'] as String?,
        toDate: params['to_date'] as String?,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat neraca keuangan')));
    }
  }

  @override
  Future<Either<Failure, ProfitLossEntity>> getProfitLoss(
      ReportFilterEntity filter) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final params = filter.toQueryParams();
      final result = await remoteDataSource.getProfitLoss(
        period: params['period'] as String,
        branchId: params['branch_id'] as String?,
        fromDate: params['from_date'] as String?,
        toDate: params['to_date'] as String?,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat laporan laba rugi')));
    }
  }

  @override
  Future<Either<Failure, CashFlowEntity>> getCashFlow(
      ReportFilterEntity filter) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final params = filter.toQueryParams();
      final result = await remoteDataSource.getCashFlow(
        period: params['period'] as String,
        branchId: params['branch_id'] as String?,
        fromDate: params['from_date'] as String?,
        toDate: params['to_date'] as String?,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat laporan arus kas')));
    }
  }

  @override
  Future<Either<Failure, LedgerEntity>> getLedger({
    required ReportFilterEntity filter,
    String? accountId,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final params = filter.toQueryParams();
      final result = await remoteDataSource.getLedger(
        accountId: accountId,
        period: params['period'] as String,
        fromDate: params['from_date'] as String?,
        toDate: params['to_date'] as String?,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat buku besar')));
    }
  }

  @override
  Future<Either<Failure, TrialBalanceEntity>> getTrialBalance(
      ReportFilterEntity filter) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final params = filter.toQueryParams();
      final result = await remoteDataSource.getTrialBalance(
        period: params['period'] as String,
        branchId: params['branch_id'] as String?,
        fromDate: params['from_date'] as String?,
        toDate: params['to_date'] as String?,
      );
      return Right(result.toEntity());
    } on DioException catch (e) {
      return Left(ServerFailure(_extractError(e, 'Gagal memuat neraca saldo')));
    }
  }
}
