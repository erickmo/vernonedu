import 'package:equatable/equatable.dart';

class PayableEntity extends Equatable {
  final String id;
  final String type;
  // Values: facilitator | commission_op_leader | commission_dept_leader |
  //         commission_course_creator | marketing_partner | other
  final String recipientId;
  final String recipientName;
  final String? recipientRole;
  final String? batchId;
  final String? batchCode;
  final double amount;
  final String status; // pending | approved | paid | cancelled
  final DateTime date;
  final DateTime? dueDate;
  final String source; // auto | manual

  // Facilitator-specific
  final String? facilitatorLevel;
  final int? sessionCount;
  final double? feePerSession;

  // Commission-specific
  final String? basisType; // profit | revenue
  final double? commissionPercent;

  // Marketing partner-specific
  final String? referralCode;
  final String? studentName;

  final String? paymentProof;
  final String? notes;

  const PayableEntity({
    required this.id,
    required this.type,
    required this.recipientId,
    required this.recipientName,
    this.recipientRole,
    this.batchId,
    this.batchCode,
    required this.amount,
    required this.status,
    required this.date,
    this.dueDate,
    required this.source,
    this.facilitatorLevel,
    this.sessionCount,
    this.feePerSession,
    this.basisType,
    this.commissionPercent,
    this.referralCode,
    this.studentName,
    this.paymentProof,
    this.notes,
  });

  String get typeLabel {
    switch (type) {
      case 'facilitator':
        return 'Fasilitator';
      case 'commission_op_leader':
        return 'Komisi Op Leader';
      case 'commission_dept_leader':
        return 'Komisi Dept Leader';
      case 'commission_course_creator':
        return 'Komisi Course Creator';
      case 'marketing_partner':
        return 'Marketing Partner';
      default:
        return 'Lainnya';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Disetujui';
      case 'paid':
        return 'Dibayar';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        recipientId,
        recipientName,
        recipientRole,
        batchId,
        batchCode,
        amount,
        status,
        date,
        dueDate,
        source,
        facilitatorLevel,
        sessionCount,
        feePerSession,
        basisType,
        commissionPercent,
        referralCode,
        studentName,
        paymentProof,
        notes,
      ];
}

class PayableStatsEntity extends Equatable {
  final double totalPayable;
  final double facilitatorPayable;
  final double commissionPayable;
  final double marketingPartnerPayable;
  final int dueThisWeekCount;
  final double dueThisWeekAmount;

  const PayableStatsEntity({
    required this.totalPayable,
    required this.facilitatorPayable,
    required this.commissionPayable,
    required this.marketingPartnerPayable,
    required this.dueThisWeekCount,
    required this.dueThisWeekAmount,
  });

  @override
  List<Object?> get props => [
        totalPayable,
        facilitatorPayable,
        commissionPayable,
        marketingPartnerPayable,
        dueThisWeekCount,
        dueThisWeekAmount,
      ];
}
