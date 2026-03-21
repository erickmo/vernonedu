import '../../domain/entities/referral_entity.dart';

class ReferralModel extends ReferralEntity {
  const ReferralModel({
    required super.id,
    required super.partnerName,
    required super.status,
    required super.commission,
    required super.createdAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) => ReferralModel(
        id: json['id'] as String? ?? '',
        partnerName: json['partner_name'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
        createdAt: json['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (json['created_at'] as int) * 1000)
            : DateTime.now(),
      );

  ReferralEntity toEntity() => ReferralEntity(
        id: id,
        partnerName: partnerName,
        status: status,
        commission: commission,
        createdAt: createdAt,
      );
}
