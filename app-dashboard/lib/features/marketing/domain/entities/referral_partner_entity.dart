import 'package:equatable/equatable.dart';

class ReferralPartnerEntity extends Equatable {
  final String id;
  final String name;
  final String contactEmail;
  final String referralCode;
  final String commissionType;
  final double commissionValue;
  final double totalCommission;
  final double pendingCommission;
  final int totalReferrals;
  final int totalEnrolled;
  final bool isActive;
  final DateTime createdAt;

  const ReferralPartnerEntity({
    required this.id,
    required this.name,
    required this.contactEmail,
    required this.referralCode,
    required this.commissionType,
    required this.commissionValue,
    required this.totalCommission,
    required this.pendingCommission,
    required this.totalReferrals,
    required this.totalEnrolled,
    required this.isActive,
    required this.createdAt,
  });

  String get commissionDisplay => commissionType == 'percentage'
      ? '${commissionValue.toStringAsFixed(1)}%'
      : 'Rp ${commissionValue.toStringAsFixed(0)}';

  @override
  List<Object?> get props => [id, isActive, commissionValue];
}
