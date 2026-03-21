import '../../domain/entities/partnership_log_entity.dart';

class PartnershipLogModel {
  final String id;
  final String logDate;
  final String entityName;
  final String entityType;
  final String status;
  final String notes;

  const PartnershipLogModel({
    required this.id,
    required this.logDate,
    required this.entityName,
    required this.entityType,
    required this.status,
    required this.notes,
  });

  factory PartnershipLogModel.fromJson(Map<String, dynamic> json) {
    return PartnershipLogModel(
      id: json['id']?.toString() ?? '',
      logDate: json['log_date']?.toString() ?? '',
      entityName: json['entity_name']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  PartnershipLogEntity toEntity() {
    return PartnershipLogEntity(
      id: id,
      logDate: logDate,
      entityName: entityName,
      entityType: entityType,
      status: status,
      notes: notes,
    );
  }
}
