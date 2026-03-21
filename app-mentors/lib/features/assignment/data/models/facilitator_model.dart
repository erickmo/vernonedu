import '../../domain/entities/facilitator_entity.dart';

class FacilitatorModel {
  final String id;
  final String name;
  final String email;
  final String? departmentName;
  final int activeBatchCount;
  final String? photoUrl;

  const FacilitatorModel({
    required this.id,
    required this.name,
    required this.email,
    this.departmentName,
    required this.activeBatchCount,
    this.photoUrl,
  });

  factory FacilitatorModel.fromJson(Map<String, dynamic> json) =>
      FacilitatorModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        departmentName: json['department_name'] as String?,
        activeBatchCount: json['active_batch_count'] as int? ?? 0,
        photoUrl: json['photo_url'] as String?,
      );

  FacilitatorEntity toEntity() => FacilitatorEntity(
        id: id,
        name: name,
        email: email,
        departmentName: departmentName,
        activeBatchCount: activeBatchCount,
        photoUrl: photoUrl,
      );
}
