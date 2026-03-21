import 'package:equatable/equatable.dart';

class BudgetItemEntity extends Equatable {
  final String category;
  final bool isPendapatan;
  final double anggaran;
  final double realisasi;

  const BudgetItemEntity({
    required this.category,
    required this.isPendapatan,
    required this.anggaran,
    required this.realisasi,
  });

  double get persentase =>
      anggaran > 0 ? (realisasi / anggaran * 100).clamp(0.0, 100.0) : 0.0;

  @override
  List<Object?> get props => [category, isPendapatan, anggaran, realisasi];
}
