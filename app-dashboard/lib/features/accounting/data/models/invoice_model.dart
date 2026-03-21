import '../../domain/entities/invoice_entity.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.studentName,
    required super.batchName,
    required super.paymentMethod,
    required super.amount,
    required super.dueDate,
    required super.status,
    required super.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        id: json['id'] as String? ?? '',
        invoiceNumber: json['invoice_number'] as String? ?? '',
        studentName: json['student_name'] as String? ?? '',
        batchName: json['batch_name'] as String? ?? '',
        paymentMethod: json['payment_method'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        dueDate: json['due_date'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        createdAt: json['created_at'] as String? ?? '',
      );

  InvoiceEntity toEntity() => InvoiceEntity(
        id: id,
        invoiceNumber: invoiceNumber,
        studentName: studentName,
        batchName: batchName,
        paymentMethod: paymentMethod,
        amount: amount,
        dueDate: dueDate,
        status: status,
        createdAt: createdAt,
      );
}
