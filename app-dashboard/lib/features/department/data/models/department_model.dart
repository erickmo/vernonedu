import '../../domain/entities/department_entity.dart';

class DepartmentModel {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final bool isActive;

  const DepartmentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.isActive,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) => DepartmentModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    leaderId: json['leader_id'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
  );

  DepartmentEntity toEntity() => DepartmentEntity(
    id: id,
    name: name,
    description: description,
    leaderId: leaderId,
    isActive: isActive,
  );
}
