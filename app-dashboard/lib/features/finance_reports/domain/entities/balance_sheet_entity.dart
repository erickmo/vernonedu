import 'package:equatable/equatable.dart';

class BalanceSheetAccountEntity extends Equatable {
  final String code;
  final String name;
  final double amount;
  final bool isNegative;
  final List<BalanceSheetAccountEntity> children;

  const BalanceSheetAccountEntity({
    required this.code,
    required this.name,
    required this.amount,
    this.isNegative = false,
    this.children = const [],
  });

  @override
  List<Object?> get props => [code, name, amount, isNegative, children];
}

class BalanceSheetSectionEntity extends Equatable {
  final String name;
  final double total;
  final List<BalanceSheetAccountEntity> accounts;

  const BalanceSheetSectionEntity({
    required this.name,
    required this.total,
    required this.accounts,
  });

  @override
  List<Object?> get props => [name, total, accounts];
}

class BalanceSheetEntity extends Equatable {
  final List<BalanceSheetSectionEntity> assetSections;
  final List<BalanceSheetSectionEntity> liabilitySections;
  final List<BalanceSheetSectionEntity> equitySections;
  final double totalAssets;
  final double totalLiabilitiesAndEquity;

  const BalanceSheetEntity({
    required this.assetSections,
    required this.liabilitySections,
    required this.equitySections,
    required this.totalAssets,
    required this.totalLiabilitiesAndEquity,
  });

  bool get isBalanced => (totalAssets - totalLiabilitiesAndEquity).abs() < 0.01;

  @override
  List<Object?> get props => [
        assetSections,
        liabilitySections,
        equitySections,
        totalAssets,
        totalLiabilitiesAndEquity,
      ];
}
