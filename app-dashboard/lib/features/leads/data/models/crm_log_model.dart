import '../../domain/entities/crm_log_entity.dart';

class CrmLogModel extends CrmLogEntity {
  const CrmLogModel({
    required super.id,
    required super.leadId,
    required super.contactedById,
    required super.contactMethod,
    required super.response,
    super.followUpDate,
    required super.createdAt,
  });

  factory CrmLogModel.fromJson(Map<String, dynamic> json) => CrmLogModel(
        id: json['id'] as String,
        leadId: json['lead_id'] as String? ?? '',
        contactedById: json['contacted_by_id'] as String? ?? '',
        contactMethod: json['contact_method'] as String? ?? 'phone',
        response: json['response'] as String? ?? '',
        followUpDate: json['follow_up_date'] != null
            ? DateTime.tryParse(json['follow_up_date'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  CrmLogEntity toEntity() => CrmLogEntity(
        id: id,
        leadId: leadId,
        contactedById: contactedById,
        contactMethod: contactMethod,
        response: response,
        followUpDate: followUpDate,
        createdAt: createdAt,
      );
}
