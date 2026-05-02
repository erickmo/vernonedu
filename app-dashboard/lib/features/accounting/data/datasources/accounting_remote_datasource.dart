import 'package:dio/dio.dart';
import '../models/accounting_stats_model.dart';
import '../models/transaction_model.dart';
import '../models/invoice_model.dart';
import '../models/coa_model.dart';
import '../models/budget_item_model.dart';
import '../models/bank_account_model.dart';
import '../models/coa_tree_node_model.dart';

abstract class AccountingRemoteDataSource {
  Future<AccountingStatsModel> getStats({
    required int month,
    required int year,
  });

  Future<List<TransactionModel>> getTransactions({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? type,
  });

  Future<void> createTransaction({required Map<String, dynamic> body});

  Future<List<InvoiceModel>> getInvoices({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? status,
  });

  Future<void> updateInvoiceStatus({
    required String id,
    required String status,
  });

  Future<List<CoaModel>> getCoa();

  Future<List<BudgetItemModel>> getBudgetVsActual({
    required int month,
    required int year,
  });

  Future<List<BankAccountModel>> listBankAccounts({
    String? branchId,
    bool includeInactive = false,
  });

  Future<void> createBankAccount({required Map<String, dynamic> body});

  Future<BankAccountModel> getBankAccount(String id);

  Future<void> updateBankAccount({
    required String id,
    required Map<String, dynamic> body,
  });

  Future<void> deleteBankAccount(String id);

  Future<List<CoaTreeNodeModel>> getCoaTree();
}

class AccountingRemoteDataSourceImpl implements AccountingRemoteDataSource {
  final Dio _dio;
  const AccountingRemoteDataSourceImpl(this._dio);

  @override
  Future<AccountingStatsModel> getStats({
    required int month,
    required int year,
  }) async {
    final res = await _dio.get(
      '/accounting/stats',
      queryParameters: {'month': month, 'year': year},
    );
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return AccountingStatsModel.fromJson(json);
  }

  @override
  Future<List<TransactionModel>> getTransactions({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? type,
  }) async {
    final params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
      'month': month,
      'year': year,
    };
    if (type != null && type.isNotEmpty) params['type'] = type;

    final res = await _dio.get('/accounting/transactions', queryParameters: params);
    final raw = res.data;

    List list;
    if (raw is Map && raw['data'] != null) {
      final inner = raw['data'];
      if (inner is List) {
        list = inner;
      } else if (inner is Map && inner['data'] != null) {
        list = inner['data'] as List;
      } else {
        list = [];
      }
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }

    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createTransaction({required Map<String, dynamic> body}) async {
    await _dio.post('/accounting/transactions', data: body);
  }

  @override
  Future<List<InvoiceModel>> getInvoices({
    required int offset,
    required int limit,
    required int month,
    required int year,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
      'month': month,
      'year': year,
    };
    if (status != null && status.isNotEmpty) params['status'] = status;

    final res = await _dio.get('/accounting/invoices', queryParameters: params);
    final raw = res.data;

    List list;
    if (raw is Map && raw['data'] != null) {
      final inner = raw['data'];
      if (inner is List) {
        list = inner;
      } else if (inner is Map && inner['data'] != null) {
        list = inner['data'] as List;
      } else {
        list = [];
      }
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }

    return list
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateInvoiceStatus({
    required String id,
    required String status,
  }) async {
    await _dio.put('/accounting/invoices/$id/status', data: {'status': status});
  }

  @override
  Future<List<CoaModel>> getCoa() async {
    final res = await _dio.get('/accounting/coa');
    final raw = res.data;

    List list;
    if (raw is Map && raw['data'] != null) {
      final inner = raw['data'];
      if (inner is List) {
        list = inner;
      } else {
        list = [];
      }
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }

    return list
        .map((e) => CoaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BudgetItemModel>> getBudgetVsActual({
    required int month,
    required int year,
  }) async {
    final res = await _dio.get(
      '/accounting/budget-vs-actual',
      queryParameters: {'month': month, 'year': year},
    );
    final raw = res.data;

    List list;
    if (raw is Map && raw['data'] != null) {
      final inner = raw['data'];
      if (inner is List) {
        list = inner;
      } else {
        list = [];
      }
    } else if (raw is List) {
      list = raw;
    } else {
      list = [];
    }

    return list
        .map((e) => BudgetItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // -------- Bank Accounts --------

  @override
  Future<List<BankAccountModel>> listBankAccounts({
    String? branchId,
    bool includeInactive = false,
  }) async {
    final params = <String, dynamic>{};
    if (branchId != null && branchId.isNotEmpty) params['branch_id'] = branchId;
    if (includeInactive) params['include_inactive'] = 'true';

    final res = await _dio.get(
      '/accounting/bank-accounts',
      queryParameters: params.isEmpty ? null : params,
    );
    final raw = res.data;
    final list = (raw is Map && raw['data'] is List)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => BankAccountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createBankAccount({required Map<String, dynamic> body}) async {
    await _dio.post('/accounting/bank-accounts', data: body);
  }

  @override
  Future<BankAccountModel> getBankAccount(String id) async {
    final res = await _dio.get('/accounting/bank-accounts/$id');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return BankAccountModel.fromJson(json);
  }

  @override
  Future<void> updateBankAccount({
    required String id,
    required Map<String, dynamic> body,
  }) async {
    await _dio.put('/accounting/bank-accounts/$id', data: body);
  }

  @override
  Future<void> deleteBankAccount(String id) async {
    await _dio.delete('/accounting/bank-accounts/$id');
  }

  // -------- Chart of Accounts (Tree) --------

  @override
  Future<List<CoaTreeNodeModel>> getCoaTree() async {
    final res = await _dio.get('/accounting/coa/tree');
    final raw = res.data;
    final list = (raw is Map && raw['data'] is List)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];
    return list
        .map((e) => CoaTreeNodeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
