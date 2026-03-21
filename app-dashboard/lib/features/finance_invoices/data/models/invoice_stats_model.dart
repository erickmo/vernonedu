import '../../domain/entities/invoice_stats_entity.dart';

class InvoiceStatsModel extends InvoiceStatsEntity {
  const InvoiceStatsModel({
    required super.totalCount,
    required super.paidCount,
    required super.paidAmount,
    required super.outstandingCount,
    required super.outstandingAmount,
    required super.overdueCount,
    required super.overdueAmount,
  });

  factory InvoiceStatsModel.fromJson(Map<String, dynamic> json) =>
      InvoiceStatsModel(
        totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
        paidCount: (json['paid_count'] as num?)?.toInt() ?? 0,
        paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
        outstandingCount:
            (json['outstanding_count'] as num?)?.toInt() ?? 0,
        outstandingAmount:
            (json['outstanding_amount'] as num?)?.toDouble() ?? 0,
        overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
        overdueAmount: (json['overdue_amount'] as num?)?.toDouble() ?? 0,
      );

  static InvoiceStatsModel mock() => const InvoiceStatsModel(
        totalCount: 15,
        paidCount: 6,
        paidAmount: 14500000,
        outstandingCount: 5,
        outstandingAmount: 9800000,
        overdueCount: 4,
        overdueAmount: 7200000,
      );

  InvoiceStatsEntity toEntity() => InvoiceStatsEntity(
        totalCount: totalCount,
        paidCount: paidCount,
        paidAmount: paidAmount,
        outstandingCount: outstandingCount,
        outstandingAmount: outstandingAmount,
        overdueCount: overdueCount,
        overdueAmount: overdueAmount,
      );
}
