import 'package:flutter_test/flutter_test.dart';
import 'package:vernonedu_dashboard/features/finance_invoices/data/models/invoice_detail_model.dart';

void main() {
  test('InvoiceDetailModel.fromJson parses backend invoice payload', () {
    final json = {
      'id': '11111111-1111-1111-1111-111111111111',
      'invoice_number': 'INV-2026-0001',
      'student_name': 'Budi',
      'batch_name': 'WD-A',
      'client_name': 'Budi Inc',
      'payment_method': 'upfront',
      'amount': 2500000.0,
      'due_date': '2026-06-01',
      'status': 'sent',
      'source': 'auto',
      'notes': 'note',
      'created_at': '2026-05-01T10:00:00Z',
      'updated_at': '2026-05-01T10:00:00Z',
    };

    final model = InvoiceDetailModel.fromJson(json);

    expect(model.id, '11111111-1111-1111-1111-111111111111');
    expect(model.invoiceNumber, 'INV-2026-0001');
    expect(model.studentName, 'Budi');
    expect(model.amount, 2500000.0);
    expect(model.status, 'sent');
    expect(model.source, 'auto');
    expect(model.paymentHistory, isEmpty);
  });
}
