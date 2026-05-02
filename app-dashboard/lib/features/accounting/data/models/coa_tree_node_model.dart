import '../../domain/entities/coa_tree_node_entity.dart';

class CoaTreeNodeModel extends CoaTreeNodeEntity {
  const CoaTreeNodeModel({
    required super.id,
    required super.code,
    required super.name,
    required super.accountType,
    required super.parentCode,
    required super.isActive,
    super.balance,
    super.children = const [],
  });

  factory CoaTreeNodeModel.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final List<CoaTreeNodeModel> children = (rawChildren is List)
        ? rawChildren
            .whereType<Map<String, dynamic>>()
            .map(CoaTreeNodeModel.fromJson)
            .toList()
        : const [];
    return CoaTreeNodeModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      accountType: json['account_type'] as String? ?? '',
      parentCode: json['parent_code'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      balance: json['balance'] as num?,
      children: children,
    );
  }

  CoaTreeNodeEntity toEntity() => CoaTreeNodeEntity(
        id: id,
        code: code,
        name: name,
        accountType: accountType,
        parentCode: parentCode,
        isActive: isActive,
        balance: balance,
        children: children
            .map((c) => (c as CoaTreeNodeModel).toEntity())
            .toList(),
      );
}
