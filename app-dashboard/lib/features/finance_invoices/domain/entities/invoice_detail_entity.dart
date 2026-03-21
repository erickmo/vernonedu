import 'package:equatable/equatable.dart';

class PaymentHistoryEntry extends Equatable {
  final String id;
  final DateTime paidAt;
  final double amount;
  final String method;
  final String? proofUrl;
  final String recordedBy;

  const PaymentHistoryEntry({
    required this.id,
    required this.paidAt,
    required this.amount,
    required this.method,
    this.proofUrl,
    required this.recordedBy,
  });

  @override
  List<Object?> get props => [id, paidAt, amount, method, proofUrl, recordedBy];
}

class InvoiceDetailEntity extends Equatable {
  final String id;
  final String invoiceNumber;
  final String studentName;
  final String studentContact;
  final String batchCode;
  final String batchName;
  final String courseTypeName;
  final String paymentMethod;
  final double amount;
  final DateTime createdAt;
  final DateTime dueDate;
  final String status;
  final String source;
  final String? notes;
  final String? cancelReason;
  final List<PaymentHistoryEntry> paymentHistory;

  const InvoiceDetailEntity({
    required this.id,
    required this.invoiceNumber,
    required this.studentName,
    required this.studentContact,
    required this.batchCode,
    required this.batchName,
    required this.courseTypeName,
    required this.paymentMethod,
    required this.amount,
    required this.createdAt,
    required this.dueDate,
    required this.status,
    required this.source,
    this.notes,
    this.cancelReason,
    required this.paymentHistory,
  });

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        studentName,
        studentContact,
        batchCode,
        batchName,
        courseTypeName,
        paymentMethod,
        amount,
        createdAt,
        dueDate,
        status,
        source,
        notes,
        cancelReason,
        paymentHistory,
      ];
}
