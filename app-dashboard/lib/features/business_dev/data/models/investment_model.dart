import '../../domain/entities/investment_entity.dart';

class InvestmentPlanModel {
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

  const InvestmentPlanModel({
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

  factory InvestmentPlanModel.fromJson(Map<String, dynamic> json) {
    return InvestmentPlanModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      proposedBy: json['proposed_by']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      expectedRoi: (json['expected_roi'] as num?)?.toDouble() ?? 0.0,
      actualSpend: (json['actual_spend'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'draft',
      approvedBy: json['approved_by']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  InvestmentPlanEntity toEntity() {
    return InvestmentPlanEntity(
      id: id,
      title: title,
      category: category,
      proposedBy: proposedBy,
      amount: amount,
      expectedRoi: expectedRoi,
      actualSpend: actualSpend,
      status: status,
      approvedBy: approvedBy,
      notes: notes,
    );
  }
}

class InvestmentStatsModel {
  final int totalPlanned;
  final int ongoingCount;
  final int ongoingAmount;
  final int completedCount;
  final int completedAmount;
  final double avgRoi;

  const InvestmentStatsModel({
    required this.totalPlanned,
    required this.ongoingCount,
    required this.ongoingAmount,
    required this.completedCount,
    required this.completedAmount,
    required this.avgRoi,
  });

  factory InvestmentStatsModel.fromJson(Map<String, dynamic> json) {
    return InvestmentStatsModel(
      totalPlanned: (json['total_planned'] as num?)?.toInt() ?? 0,
      ongoingCount: (json['ongoing_count'] as num?)?.toInt() ?? 0,
      ongoingAmount: (json['ongoing_amount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      completedAmount: (json['completed_amount'] as num?)?.toInt() ?? 0,
      avgRoi: (json['avg_roi'] as num?)?.toDouble() ?? 0.0,
    );
  }

  InvestmentStatsEntity toEntity() {
    return InvestmentStatsEntity(
      totalPlanned: totalPlanned,
      ongoingCount: ongoingCount,
      ongoingAmount: ongoingAmount,
      completedCount: completedCount,
      completedAmount: completedAmount,
      avgRoi: avgRoi,
    );
  }
}
