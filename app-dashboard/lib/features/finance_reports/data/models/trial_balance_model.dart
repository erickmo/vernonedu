import '../../domain/entities/trial_balance_entity.dart';

class TrialBalanceAccountModel {
  final String code;
  final String name;
  final double debit;
  final double credit;

  const TrialBalanceAccountModel({
    required this.code,
    required this.name,
    required this.debit,
    required this.credit,
  });

  factory TrialBalanceAccountModel.fromJson(Map<String, dynamic> json) {
    return TrialBalanceAccountModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  TrialBalanceAccountEntity toEntity() => TrialBalanceAccountEntity(
        code: code,
        name: name,
        debit: debit,
        credit: credit,
      );
}

class TrialBalanceModel {
  final List<TrialBalanceAccountModel> accounts;
  final double totalDebit;
  final double totalCredit;

  const TrialBalanceModel({
    required this.accounts,
    required this.totalDebit,
    required this.totalCredit,
  });

  factory TrialBalanceModel.fromJson(Map<String, dynamic> json) {
    return TrialBalanceModel(
      accounts: (json['accounts'] as List<dynamic>?)
              ?.map((e) =>
                  TrialBalanceAccountModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory TrialBalanceModel.mock() {
    return const TrialBalanceModel(
      totalDebit: 762000000,
      totalCredit: 762000000,
      accounts: [
        TrialBalanceAccountModel(
            code: '1-1100', name: 'Kas', debit: 45000000, credit: 0),
        TrialBalanceAccountModel(
            code: '1-1200',
            name: 'Bank BCA - Operasional',
            debit: 125000000,
            credit: 0),
        TrialBalanceAccountModel(
            code: '1-1300', name: 'Piutang Usaha', debit: 85000000, credit: 0),
        TrialBalanceAccountModel(
            code: '1-1400',
            name: 'Biaya Dibayar Dimuka',
            debit: 30000000,
            credit: 0),
        TrialBalanceAccountModel(
            code: '1-2100',
            name: 'Peralatan Komputer',
            debit: 120000000,
            credit: 0),
        TrialBalanceAccountModel(
            code: '1-2200',
            name: 'Furniture & Perlengkapan',
            debit: 75000000,
            credit: 0),
        TrialBalanceAccountModel(
            code: '1-2900',
            name: 'Akumulasi Penyusutan',
            debit: 0,
            credit: 45000000),
        TrialBalanceAccountModel(
            code: '2-1100', name: 'Hutang Usaha', debit: 0, credit: 35000000),
        TrialBalanceAccountModel(
            code: '2-1200',
            name: 'Biaya Yang Masih Harus Dibayar',
            debit: 0,
            credit: 25000000),
        TrialBalanceAccountModel(
            code: '2-1300',
            name: 'Pendapatan Diterima Dimuka',
            debit: 0,
            credit: 35000000),
        TrialBalanceAccountModel(
            code: '2-2100',
            name: 'Hutang Bank Jangka Panjang',
            debit: 0,
            credit: 50000000),
        TrialBalanceAccountModel(
            code: '3-1000', name: 'Modal Disetor', debit: 0, credit: 200000000),
        TrialBalanceAccountModel(
            code: '3-2000', name: 'Laba Ditahan', debit: 0, credit: 65000000),
        TrialBalanceAccountModel(
            code: '4-1100',
            name: 'Pendapatan Program Karir',
            debit: 0,
            credit: 95000000),
        TrialBalanceAccountModel(
            code: '4-1200',
            name: 'Pendapatan Kursus Reguler',
            debit: 0,
            credit: 60000000),
        TrialBalanceAccountModel(
            code: '4-1300',
            name: 'Pendapatan Privat',
            debit: 0,
            credit: 30000000),
        TrialBalanceAccountModel(
            code: '4-2000',
            name: 'Pendapatan Lain-lain',
            debit: 0,
            credit: 15000000),
        TrialBalanceAccountModel(
            code: '5-1000',
            name: 'Biaya Fasilitator',
            debit: 55000000,
            credit: 0),
        TrialBalanceAccountModel(
            code: '5-2000',
            name: 'Biaya Bahan Ajar',
            debit: 12000000,
            credit: 0),
        TrialBalanceAccountModel(
            code: '6-1000', name: 'Gaji Karyawan', debit: 65000000, credit: 0),
        TrialBalanceAccountModel(
            code: '6-2000',
            name: 'Sewa Gedung & Utilitas',
            debit: 25000000,
            credit: 0),
        TrialBalanceAccountModel(
            code: '6-3000',
            name: 'Biaya Marketing',
            debit: 8000000,
            credit: 0),
        TrialBalanceAccountModel(
            code: '6-4000',
            name: 'Biaya Operasional Lain',
            debit: 5000000,
            credit: 0),
        TrialBalanceAccountModel(
            code: '6-5000',
            name: 'Biaya Penyusutan',
            debit: 12000000,
            credit: 0),
      ],
    );
  }

  TrialBalanceEntity toEntity() => TrialBalanceEntity(
        accounts: accounts.map((a) => a.toEntity()).toList(),
        totalDebit: totalDebit,
        totalCredit: totalCredit,
      );
}
