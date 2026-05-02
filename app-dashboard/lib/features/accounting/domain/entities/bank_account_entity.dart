import 'package:equatable/equatable.dart';

/// Bank or cash account on the accounting ledger.
///
/// Mirrors backend `BankAccountView` (see api/internal/query/list_bank_accounts).
class BankAccountEntity extends Equatable {
  final String id;
  final String branchId;
  final String name;
  final String bankName;
  final String accountNumber;

  /// Balance in cents (smallest currency unit). Backend stores `balance_cents`.
  final int balanceCents;
  final String currency;
  final String coaCode;
  final bool isActive;

  const BankAccountEntity({
    required this.id,
    required this.branchId,
    required this.name,
    required this.bankName,
    required this.accountNumber,
    required this.balanceCents,
    required this.currency,
    required this.coaCode,
    required this.isActive,
  });

  /// Convenience accessor — balance as a major-unit double (Rupiah, USD, etc.).
  double get balance => balanceCents / 100.0;

  @override
  List<Object?> get props => [
        id,
        branchId,
        name,
        bankName,
        accountNumber,
        balanceCents,
        currency,
        coaCode,
        isActive,
      ];
}
