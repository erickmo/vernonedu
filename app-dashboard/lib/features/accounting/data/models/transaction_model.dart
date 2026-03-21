import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.referenceNumber,
    required super.description,
    required super.transactionType,
    required super.amount,
    required super.category,
    required super.transactionDate,
    required super.status,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String? ?? '',
        referenceNumber: json['reference_number'] as String? ?? '',
        description: json['description'] as String? ?? '',
        transactionType: json['transaction_type'] as String? ?? 'expense',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        category: json['category'] as String? ?? '',
        transactionDate: json['transaction_date'] as String? ?? '',
        status: json['status'] as String? ?? 'completed',
      );

  TransactionEntity toEntity() => TransactionEntity(
        id: id,
        referenceNumber: referenceNumber,
        description: description,
        transactionType: transactionType,
        amount: amount,
        category: category,
        transactionDate: transactionDate,
        status: status,
      );
}
