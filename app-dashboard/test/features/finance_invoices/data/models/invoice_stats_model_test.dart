import 'package:flutter_test/flutter_test.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/data/models/invoice_stats_model.dart';

void main() {
  test('InvoiceStatsModel.fromJson parses backend stats payload', () {
    final json = {
      'total_count': 10,
      'total_amount': 1000000.0,
      'paid_count': 4,
      'paid_amount': 400000.0,
      'outstanding_count': 4,
      'outstanding_amount': 400000.0,
      'overdue_count': 2,
      'overdue_amount': 200000.0,
    };

    final model = InvoiceStatsModel.fromJson(json);

    expect(model.totalCount, 10);
    expect(model.paidCount, 4);
    expect(model.paidAmount, 400000.0);
    expect(model.outstandingCount, 4);
    expect(model.outstandingAmount, 400000.0);
    expect(model.overdueCount, 2);
    expect(model.overdueAmount, 200000.0);
  });

  test('InvoiceStatsModel.fromJson handles missing fields with defaults', () {
    final model = InvoiceStatsModel.fromJson(<String, dynamic>{});
    expect(model.totalCount, 0);
    expect(model.paidAmount, 0);
  });
}
