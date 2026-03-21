import 'package:equatable/equatable.dart';

class InvestmentPlanEntity extends Equatable {
  final String id;
  final String title;
  final String category;
  final String proposedBy;
  final int amount;
  final double expectedRoi;
  final int actualSpend;
  final String status;
  final String approvedBy;
  final String notes;

  const InvestmentPlanEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.proposedBy,
    required this.amount,
    required this.expectedRoi,
    required this.actualSpend,
    required this.status,
    required this.approvedBy,
    required this.notes,
  });

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'proposed':
        return 'Diajukan';
      case 'approved':
        return 'Disetujui';
      case 'in_progress':
        return 'Berjalan';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [id];
}

class InvestmentStatsEntity extends Equatable {
  final int totalPlanned;
  final int ongoingCount;
  final int ongoingAmount;
  final int completedCount;
  final int completedAmount;
  final double avgRoi;

  const InvestmentStatsEntity({
    required this.totalPlanned,
    required this.ongoingCount,
    required this.ongoingAmount,
    required this.completedCount,
    required this.completedAmount,
    required this.avgRoi,
  });

  @override
  List<Object?> get props => [totalPlanned];
}
