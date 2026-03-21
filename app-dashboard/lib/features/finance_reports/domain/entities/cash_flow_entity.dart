import 'package:equatable/equatable.dart';

class CashFlowLineEntity extends Equatable {
  final String name;
  final double amount;
  final bool isSubtotal;

  const CashFlowLineEntity({
    required this.name,
    required this.amount,
    this.isSubtotal = false,
  });

  @override
  List<Object?> get props => [name, amount, isSubtotal];
}

class CashFlowSectionEntity extends Equatable {
  final String name;
  final List<CashFlowLineEntity> lines;
  final double netCash;

  const CashFlowSectionEntity({
    required this.name,
    required this.lines,
    required this.netCash,
  });

  @override
  List<Object?> get props => [name, lines, netCash];
}

class MonthlyCashPoint extends Equatable {
  final String label;
  final double balance;

  const MonthlyCashPoint({required this.label, required this.balance});

  @override
  List<Object?> get props => [label, balance];
}

class CashFlowEntity extends Equatable {
  final CashFlowSectionEntity operating;
  final CashFlowSectionEntity investing;
  final CashFlowSectionEntity financing;
  final double netChange;
  final double openingBalance;
  final double closingBalance;
  final List<MonthlyCashPoint> monthlyTrend;

  const CashFlowEntity({
    required this.operating,
    required this.investing,
    required this.financing,
    required this.netChange,
    required this.openingBalance,
    required this.closingBalance,
    this.monthlyTrend = const [],
  });

  @override
  List<Object?> get props => [
        operating,
        investing,
        financing,
        netChange,
        openingBalance,
        closingBalance,
        monthlyTrend,
      ];
}
