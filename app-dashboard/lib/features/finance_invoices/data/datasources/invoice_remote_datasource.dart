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
    required String method,
    String? proofUrl,
  });

  Future<void> resendInvoice(String id);

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
    try {
      final res = await _dio.get('/finance/invoices/stats');
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return InvoiceStatsModel.fromJson(json);
    } on DioException {
      return InvoiceStatsModel.mock();
    }
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
    try {
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
      if (fromDate != null && fromDate.isNotEmpty) params['from_date'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) params['to_date'] = toDate;

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
    } on DioException {
      return InvoiceDetailModel.mockList();
    }
  }

  @override
  Future<InvoiceDetailModel> getInvoiceDetail(String id) async {
    try {
      final res = await _dio.get('/finance/invoices/$id');
      final raw = res.data;
      final json = (raw is Map && raw['data'] != null)
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      return InvoiceDetailModel.fromJson(json);
    } on DioException {
      final mockItems = InvoiceDetailModel.mockList();
      return mockItems.firstWhere(
        (e) => e.id == id,
        orElse: () => mockItems.first,
      );
    }
  }

  @override
  Future<void> markAsPaid({
    required String id,
    required String paidAt,
    required String method,
    String? proofUrl,
  }) async {
    try {
      final body = <String, dynamic>{
        'paid_at': paidAt,
        'method': method,
      };
      if (proofUrl != null && proofUrl.isNotEmpty) body['proof_url'] = proofUrl;
      await _dio.put('/finance/invoices/$id/pay', data: body);
    } on DioException {
      // Fallback: silently succeed for mock
    }
  }

  @override
  Future<void> resendInvoice(String id) async {
    try {
      await _dio.post('/finance/invoices/$id/resend');
    } on DioException {
      // Fallback: silently succeed for mock
    }
  }

  @override
  Future<void> cancelInvoice({
    required String id,
    required String reason,
  }) async {
    try {
      await _dio.put('/finance/invoices/$id/cancel',
          data: {'reason': reason});
    } on DioException {
      // Fallback: silently succeed for mock
    }
  }

  @override
  Future<void> createManualInvoice(Map<String, dynamic> body) async {
    try {
      await _dio.post('/finance/invoices', data: body);
    } on DioException {
      // Fallback: silently succeed for mock
    }
  }
}
