import 'package:equatable/equatable.dart';

/// Node in the Chart of Accounts hierarchical tree.
///
/// Mirrors backend `CoaNodeView` (see api/internal/query/list_coa_tree).
/// Backend currently does not return balance per node — exposed as nullable
/// so the UI can show "—" when absent and render a real number when present.
class CoaTreeNodeEntity extends Equatable {
  final String id;
  final String code;
  final String name;
  final String accountType;
  final String parentCode;
  final bool isActive;

  /// Balance in major currency units (e.g. Rupiah). Optional — backend may omit.
  final num? balance;

  final List<CoaTreeNodeEntity> children;

  const CoaTreeNodeEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.accountType,
    required this.parentCode,
    required this.isActive,
    this.balance,
    this.children = const [],
  });

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        accountType,
        parentCode,
        isActive,
        balance,
        children,
      ];
}
