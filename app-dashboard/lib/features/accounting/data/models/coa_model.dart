import '../../domain/entities/coa_entity.dart';

class CoaModel extends CoaEntity {
  const CoaModel({
    required super.id,
    required super.code,
    required super.name,
    required super.accountType,
    required super.parentCode,
    required super.isActive,
  });

  factory CoaModel.fromJson(Map<String, dynamic> json) => CoaModel(
        id: json['id'] as String? ?? '',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        accountType: json['account_type'] as String? ?? '',
        parentCode: json['parent_code'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
      );

  CoaEntity toEntity() => CoaEntity(
        id: id,
        code: code,
        name: name,
        accountType: accountType,
        parentCode: parentCode,
        isActive: isActive,
      );
}
