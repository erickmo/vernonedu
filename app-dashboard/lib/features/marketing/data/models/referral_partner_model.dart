import '../../domain/entities/referral_partner_entity.dart';

class ReferralPartnerModel extends ReferralPartnerEntity {
  const ReferralPartnerModel({
    required super.id,
    required super.name,
    required super.contactEmail,
    required super.referralCode,
    required super.commissionType,
    required super.commissionValue,
    required super.totalCommission,
    required super.pendingCommission,
    required super.totalReferrals,
    required super.totalEnrolled,
    required super.isActive,
    required super.createdAt,
  });

  factory ReferralPartnerModel.fromJson(Map<String, dynamic> json) =>
      ReferralPartnerModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        contactEmail: json['contact_email'] as String? ?? '',
        referralCode: json['referral_code'] as String? ?? '',
        commissionType: json['commission_type'] as String? ?? 'percentage',
        commissionValue:
            (json['commission_value'] as num?)?.toDouble() ?? 0.0,
        totalCommission:
            (json['total_commission'] as num?)?.toDouble() ?? 0.0,
        pendingCommission:
            (json['pending_commission'] as num?)?.toDouble() ?? 0.0,
        totalReferrals: json['total_referrals'] as int? ?? 0,
        totalEnrolled: json['total_enrolled'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (json['created_at'] as int) * 1000)
            : DateTime.now(),
      );

  ReferralPartnerEntity toEntity() => ReferralPartnerEntity(
        id: id,
        name: name,
        contactEmail: contactEmail,
        referralCode: referralCode,
        commissionType: commissionType,
        commissionValue: commissionValue,
        totalCommission: totalCommission,
        pendingCommission: pendingCommission,
        totalReferrals: totalReferrals,
        totalEnrolled: totalEnrolled,
        isActive: isActive,
        createdAt: createdAt,
      );
}
