import 'package:dio/dio.dart';
import '../models/balance_sheet_model.dart';
import '../models/cash_flow_model.dart';
import '../models/ledger_model.dart';
import '../models/profit_loss_model.dart';
import '../models/trial_balance_model.dart';

abstract class FinanceReportsRemoteDataSource {
  Future<BalanceSheetModel> getBalanceSheet({
    required String period,
    String? branchId,
    String? fromDate,
    String? toDate,
  });

  Future<ProfitLossModel> getProfitLoss({
    required String period,
    String? branchId,
    String? fromDate,
    String? toDate,
  });

  Future<CashFlowModel> getCashFlow({
    required String period,
    String? branchId,
    String? fromDate,
    String? toDate,
  });

  Future<LedgerModel> getLedger({
    String? accountId,
    required String period,
    String? fromDate,
    String? toDate,
  });

  Future<TrialBalanceModel> getTrialBalance({
    required String period,
    String? branchId,
    String? fromDate,
    String? toDate,
  });
}

class FinanceReportsRemoteDataSourceImpl implements FinanceReportsRemoteDataSource {
  final Dio _dio;
  const FinanceReportsRemoteDataSourceImpl(this._dio);

  Map<String, dynamic> _buildParams({
    required String period,
    String? branchId,
    String? fromDate,
    String? toDate,
  }) {
    final params = <String, dynamic>{'period': period};
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    if (fromDate != null && fromDate.isNotEmpty) params['from_date'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) params['to_date'] = toDate;
    return params;
  }

  @override
  Future<BalanceSheetModel> getBalanceSheet({
    required String period,
    String? branchId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final params = _buildParams(
        period: period,
        branchId: branchId,
        fromDate: fromDate,
        toDate: toDate,
      );
      final res = await _dio.get('/finance/reports/balance-sheet', queryParameters: params);
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return BalanceSheetModel.fromJson(json);
    } on DioException {
      return BalanceSheetModel.mock();
    } catch (_) {
      return BalanceSheetModel.mock();
    }
  }

  @override
  Future<ProfitLossModel> getProfitLoss({
    required String period,
    String? branchId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final params = _buildParams(
        period: period,
        branchId: branchId,
        fromDate: fromDate,
        toDate: toDate,
      );
      final res = await _dio.get('/finance/reports/profit-loss', queryParameters: params);
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return ProfitLossModel.fromJson(json);
    } on DioException {
      return ProfitLossModel.mock();
    } catch (_) {
      return ProfitLossModel.mock();
    }
  }

  @override
  Future<CashFlowModel> getCashFlow({
    required String period,
    String? branchId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final params = _buildParams(
        period: period,
        branchId: branchId,
        fromDate: fromDate,
        toDate: toDate,
      );
      final res = await _dio.get('/finance/reports/cash-flow', queryParameters: params);
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return CashFlowModel.fromJson(json);
    } on DioException {
      return CashFlowModel.mock();
    } catch (_) {
      return CashFlowModel.mock();
    }
  }

  @override
  Future<LedgerModel> getLedger({
    String? accountId,
    required String period,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final params = _buildParams(
        period: period,
        fromDate: fromDate,
        toDate: toDate,
      );
      if (accountId != null && accountId.isNotEmpty) params['account_id'] = accountId;
      final res = await _dio.get('/finance/reports/ledger', queryParameters: params);
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return LedgerModel.fromJson(json);
    } on DioException {
      return LedgerModel.mock();
    } catch (_) {
      return LedgerModel.mock();
    }
  }

  @override
  Future<TrialBalanceModel> getTrialBalance({
    required String period,
    String? branchId,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final params = _buildParams(
        period: period,
        branchId: branchId,
        fromDate: fromDate,
        toDate: toDate,
      );
      final res =
          await _dio.get('/finance/reports/trial-balance', queryParameters: params);
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return TrialBalanceModel.fromJson(json);
    } on DioException {
      return TrialBalanceModel.mock();
    } catch (_) {
      return TrialBalanceModel.mock();
    }
  }
}
