import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String referenceNumber;
  final String description;
  final String transactionType; // income, expense, transfer
  final double amount;
  final String category;
  final String transactionDate;
  final String status;

  const TransactionEntity({
    required this.id,
    required this.referenceNumber,
    required this.description,
    required this.transactionType,
    required this.amount,
    required this.category,
    required this.transactionDate,
    required this.status,
  });

  bool get isIncome => transactionType == 'income';

  @override
  List<Object?> get props => [
        id,
        referenceNumber,
        description,
        transactionType,
        amount,
        category,
        transactionDate,
        status,
      ];
}
