import '../../domain/entities/budget_item_entity.dart';

class BudgetItemModel extends BudgetItemEntity {
  const BudgetItemModel({
    required super.category,
    required super.isPendapatan,
    required super.anggaran,
    required super.realisasi,
  });

  factory BudgetItemModel.fromJson(Map<String, dynamic> json) =>
      BudgetItemModel(
        category: json['category'] as String? ?? '',
        isPendapatan: json['is_pendapatan'] as bool? ?? false,
        anggaran: (json['anggaran'] as num?)?.toDouble() ?? 0,
        realisasi: (json['realisasi'] as num?)?.toDouble() ?? 0,
      );

  BudgetItemEntity toEntity() => BudgetItemEntity(
        category: category,
        isPendapatan: isPendapatan,
        anggaran: anggaran,
        realisasi: realisasi,
      );
}
