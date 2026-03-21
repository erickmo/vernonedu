import 'package:equatable/equatable.dart';

class LedgerEntryEntity extends Equatable {
  final DateTime date;
  final String code;
  final String description;
  final String ref;
  final double debit;
  final double credit;
  final double balance;

  const LedgerEntryEntity({
    required this.date,
    required this.code,
    required this.description,
    required this.ref,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  @override
  List<Object?> get props => [date, code, description, ref, debit, credit, balance];
}

class LedgerEntity extends Equatable {
  final String accountCode;
  final String accountName;
  final List<LedgerEntryEntity> entries;
  final double totalDebit;
  final double totalCredit;

  const LedgerEntity({
    required this.accountCode,
    required this.accountName,
    required this.entries,
    required this.totalDebit,
    required this.totalCredit,
  });

  @override
  List<Object?> get props => [accountCode, accountName, entries, totalDebit, totalCredit];
}
