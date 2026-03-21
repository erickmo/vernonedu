import 'package:equatable/equatable.dart';

class TrialBalanceAccountEntity extends Equatable {
  final String code;
  final String name;
  final double debit;
  final double credit;

  const TrialBalanceAccountEntity({
    required this.code,
    required this.name,
    required this.debit,
    required this.credit,
  });

  @override
  List<Object?> get props => [code, name, debit, credit];
}

class TrialBalanceEntity extends Equatable {
  final List<TrialBalanceAccountEntity> accounts;
  final double totalDebit;
  final double totalCredit;

  const TrialBalanceEntity({
    required this.accounts,
    required this.totalDebit,
    required this.totalCredit,
  });

  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.01;

  @override
  List<Object?> get props => [accounts, totalDebit, totalCredit];
}
