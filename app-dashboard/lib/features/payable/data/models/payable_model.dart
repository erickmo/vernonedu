import '../../domain/entities/payable_entity.dart';

class PayableModel {
  final String id;
  final String type;
  final String recipientId;
  final String recipientName;
  final String? recipientRole;
  final String? batchId;
  final String? batchCode;
  final double amount;
  final String status;
  final String date;
  final String? dueDate;
  final String source;
  final String? facilitatorLevel;
  final int? sessionCount;
  final double? feePerSession;
  final String? basisType;
  final double? commissionPercent;
  final String? referralCode;
  final String? studentName;
  final String? paymentProof;
  final String? notes;

  const PayableModel({
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

  factory PayableModel.fromJson(Map<String, dynamic> json) => PayableModel(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        recipientId: json['recipient_id'] as String? ?? '',
        recipientName: json['recipient_name'] as String? ?? '',
        recipientRole: json['recipient_role'] as String?,
        batchId: json['batch_id'] as String?,
        batchCode: json['batch_code'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'pending',
        date: json['date'] as String? ?? '',
        dueDate: json['due_date'] as String?,
        source: json['source'] as String? ?? 'auto',
        facilitatorLevel: json['facilitator_level'] as String?,
        sessionCount: (json['session_count'] as num?)?.toInt(),
        feePerSession: (json['fee_per_session'] as num?)?.toDouble(),
        basisType: json['basis_type'] as String?,
        commissionPercent: (json['commission_percent'] as num?)?.toDouble(),
        referralCode: json['referral_code'] as String?,
        studentName: json['student_name'] as String?,
        paymentProof: json['payment_proof'] as String?,
        notes: json['notes'] as String?,
      );

  PayableEntity toEntity() => PayableEntity(
        id: id,
        type: type,
        recipientId: recipientId,
        recipientName: recipientName,
        recipientRole: recipientRole,
        batchId: batchId,
        batchCode: batchCode,
        amount: amount,
        status: status,
        date: DateTime.tryParse(date) ?? DateTime.now(),
        dueDate: dueDate != null ? DateTime.tryParse(dueDate!) : null,
        source: source,
        facilitatorLevel: facilitatorLevel,
        sessionCount: sessionCount,
        feePerSession: feePerSession,
        basisType: basisType,
        commissionPercent: commissionPercent,
        referralCode: referralCode,
        studentName: studentName,
        paymentProof: paymentProof,
        notes: notes,
      );
}

class PayableStatsModel {
  final double totalPayable;
  final double facilitatorPayable;
  final double commissionPayable;
  final double marketingPartnerPayable;
  final int dueThisWeekCount;
  final double dueThisWeekAmount;

  const PayableStatsModel({
    required this.totalPayable,
    required this.facilitatorPayable,
    required this.commissionPayable,
    required this.marketingPartnerPayable,
    required this.dueThisWeekCount,
    required this.dueThisWeekAmount,
  });

  factory PayableStatsModel.fromJson(Map<String, dynamic> json) =>
      PayableStatsModel(
        totalPayable: (json['total_payable'] as num?)?.toDouble() ?? 0,
        facilitatorPayable:
            (json['facilitator_payable'] as num?)?.toDouble() ?? 0,
        commissionPayable:
            (json['commission_payable'] as num?)?.toDouble() ?? 0,
        marketingPartnerPayable:
            (json['marketing_partner_payable'] as num?)?.toDouble() ?? 0,
        dueThisWeekCount: (json['due_this_week_count'] as num?)?.toInt() ?? 0,
        dueThisWeekAmount:
            (json['due_this_week_amount'] as num?)?.toDouble() ?? 0,
      );

  PayableStatsEntity toEntity() => PayableStatsEntity(
        totalPayable: totalPayable,
        facilitatorPayable: facilitatorPayable,
        commissionPayable: commissionPayable,
        marketingPartnerPayable: marketingPartnerPayable,
        dueThisWeekCount: dueThisWeekCount,
        dueThisWeekAmount: dueThisWeekAmount,
      );
}
