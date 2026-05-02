import 'package:dio/dio.dart';
import '../models/invoice_detail_model.dart';
import '../models/invoice_stats_model.dart';

abstract class InvoiceRemoteDataSource {
  Future<InvoiceStatsModel> getStats();

  Future<List<InvoiceDetailModel>> getInvoices({
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

  Future<InvoiceDetailModel> getInvoiceDetail(String id);

  Future<void> markAsPaid({
    required String id,
    required String paidAt,
    double? paidAmount,
    String? paymentProof,
    String? accountCode,
  });

  Future<void> sendInvoice(String id);

  Future<void> cancelInvoice({
    required String id,
    required String reason,
  });

  Future<void> createManualInvoice(Map<String, dynamic> body);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final Dio _dio;
  const InvoiceRemoteDataSourceImpl(this._dio);

  @override
  Future<InvoiceStatsModel> getStats() async {
    final res = await _dio.get('/finance/invoices/stats');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return InvoiceStatsModel.fromJson(json);
  }

  @override
  Future<List<InvoiceDetailModel>> getInvoices({
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
    final params = <String, dynamic>{
      'offset': offset,
      'limit': limit,
    };
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      params['invoice_number'] = invoiceNumber;
    }
    if (studentName != null && studentName.isNotEmpty) {
      params['student_name'] = studentName;
    }
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (batchId != null && batchId.isNotEmpty) params['batch_id'] = batchId;
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      params['payment_method'] = paymentMethod;
    }
    if (fromDate != null && fromDate.isNotEmpty) params['date_from'] = fromDate;
    if (toDate != null && toDate.isNotEmpty) params['date_to'] = toDate;

    final res = await _dio.get('/finance/invoices', queryParameters: params);
    final raw = res.data;
    final list = (raw is Map && raw['data'] != null)
        ? raw['data'] as List
        : raw is List
            ? raw
            : <dynamic>[];

    return list
        .map((e) => InvoiceDetailModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InvoiceDetailModel> getInvoiceDetail(String id) async {
    final res = await _dio.get('/finance/invoices/$id');
    final raw = res.data;
    final json = (raw is Map && raw['data'] != null)
        ? raw['data'] as Map<String, dynamic>
        : raw as Map<String, dynamic>;
    return InvoiceDetailModel.fromJson(json);
  }

  @override
  Future<void> markAsPaid({
    required String id,
    required String paidAt,
    double? paidAmount,
    String? paymentProof,
    String? accountCode,
  }) async {
    final body = <String, dynamic>{'paid_at': paidAt};
    if (paidAmount != null) body['paid_amount'] = paidAmount;
    if (paymentProof != null && paymentProof.isNotEmpty) {
      body['payment_proof'] = paymentProof;
    }
    if (accountCode != null && accountCode.isNotEmpty) {
      body['account_code'] = accountCode;
    }
    await _dio.put('/finance/invoices/$id/pay', data: body);
  }

  @override
  Future<void> sendInvoice(String id) async {
    await _dio.put('/finance/invoices/$id/send');
  }

  @override
  Future<void> cancelInvoice({
    required String id,
    required String reason,
  }) async {
    await _dio.put('/finance/invoices/$id/cancel', data: {'reason': reason});
  }

  @override
  Future<void> createManualInvoice(Map<String, dynamic> body) async {
    await _dio.post('/finance/invoices', data: body);
  }
}
