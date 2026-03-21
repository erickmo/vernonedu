import 'package:equatable/equatable.dart';

class InvoiceStatsEntity extends Equatable {
  final int totalCount;
  final int paidCount;
  final double paidAmount;
  final int outstandingCount;
  final double outstandingAmount;
  final int overdueCount;
  final double overdueAmount;

  const InvoiceStatsEntity({
    required this.totalCount,
    required this.paidCount,
    required this.paidAmount,
    required this.outstandingCount,
    required this.outstandingAmount,
    required this.overdueCount,
    required this.overdueAmount,
  });

  @override
  List<Object?> get props => [
        totalCount,
        paidCount,
        paidAmount,
        outstandingCount,
        outstandingAmount,
        overdueCount,
        overdueAmount,
      ];
}
