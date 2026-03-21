import 'package:equatable/equatable.dart';

class CoaEntity extends Equatable {
  final String id;
  final String code;
  final String name;
  final String accountType; // asset, liability, equity, revenue, expense
  final String parentCode;
  final bool isActive;

  const CoaEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.accountType,
    required this.parentCode,
    required this.isActive,
  });

  String get accountTypeLabel => switch (accountType) {
        'asset' => 'Aset',
        'liability' => 'Kewajiban',
        'equity' => 'Ekuitas',
        'revenue' => 'Pendapatan',
        'expense' => 'Beban',
        _ => accountType,
      };

  @override
  List<Object?> get props => [id, code, name, accountType, parentCode, isActive];
}
