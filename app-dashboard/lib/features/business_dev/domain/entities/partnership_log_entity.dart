import 'package:equatable/equatable.dart';

class PartnershipLogEntity extends Equatable {
  final String id;
  final String logDate;
  final String entityName;
  final String entityType;
  final String status;
  final String notes;

  const PartnershipLogEntity({
    required this.id,
    required this.logDate,
    required this.entityName,
    required this.entityType,
    required this.status,
    required this.notes,
  });

  @override
  List<Object?> get props => [id];
}
