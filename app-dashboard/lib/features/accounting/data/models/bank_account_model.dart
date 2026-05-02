import '../../domain/entities/bank_account_entity.dart';

class BankAccountModel extends BankAccountEntity {
  const BankAccountModel({
    required super.id,
    required super.branchId,
    required super.name,
    required super.bankName,
    required super.accountNumber,
    required super.balanceCents,
    required super.currency,
    required super.coaCode,
    required super.isActive,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) =>
      BankAccountModel(
        id: json['id'] as String? ?? '',
        branchId: json['branch_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        bankName: json['bank_name'] as String? ?? '',
        accountNumber: json['account_number'] as String? ?? '',
        balanceCents: (json['balance_cents'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'IDR',
        coaCode: json['coa_code'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
      );

  /// Body for POST /accounting/bank-accounts.
  Map<String, dynamic> toCreateJson() => {
        'branch_id': branchId,
        'name': name,
        'bank_name': bankName,
        'account_number': accountNumber,
        'balance_cents': balanceCents,
        'currency': currency,
        'coa_code': coaCode,
      };

  /// Body for PUT /accounting/bank-accounts/{id}. Backend ignores branch_id on update.
  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'bank_name': bankName,
        'account_number': accountNumber,
        'balance_cents': balanceCents,
        'currency': currency,
        'coa_code': coaCode,
      };

  BankAccountEntity toEntity() => BankAccountEntity(
        id: id,
        branchId: branchId,
        name: name,
        bankName: bankName,
        accountNumber: accountNumber,
        balanceCents: balanceCents,
        currency: currency,
        coaCode: coaCode,
        isActive: isActive,
      );
}
