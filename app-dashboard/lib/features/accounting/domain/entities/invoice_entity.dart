import 'package:equatable/equatable.dart';

class InvoiceEntity extends Equatable {
  final String id;
  final String invoiceNumber;
  final String studentName;
  final String batchName;
  final String paymentMethod;
  final double amount;
  final String dueDate;
  final String status; // draft, sent, paid, overdue, cancelled
  final String createdAt;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.studentName,
    required this.batchName,
    required this.paymentMethod,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        studentName,
        batchName,
        paymentMethod,
        amount,
        dueDate,
        status,
        createdAt,
      ];
}
