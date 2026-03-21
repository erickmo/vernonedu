import '../../domain/entities/lead_entity.dart';

class LeadModel extends LeadEntity {
  const LeadModel({
    required super.id,
    required super.name,
    required super.email,
    required super.phone,
    required super.interest,
    required super.source,
    required super.notes,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) => LeadModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        interest: json['interest'] as String? ?? '',
        source: json['source'] as String? ?? 'other',
        notes: json['notes'] as String? ?? '',
        status: json['status'] as String? ?? 'new',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  LeadEntity toEntity() => LeadEntity(
        id: id,
        name: name,
        email: email,
        phone: phone,
        interest: interest,
        source: source,
        notes: notes,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
