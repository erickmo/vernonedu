import '../../domain/entities/ledger_entity.dart';

class LedgerEntryModel {
  final DateTime date;
  final String code;
  final String description;
  final String ref;
  final double debit;
  final double credit;
  final double balance;

  const LedgerEntryModel({
    required this.date,
    required this.code,
    required this.description,
    required this.ref,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return LedgerEntryModel(
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      ref: json['ref']?.toString() ?? '',
      debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  LedgerEntryEntity toEntity() => LedgerEntryEntity(
        date: date,
        code: code,
        description: description,
        ref: ref,
        debit: debit,
        credit: credit,
        balance: balance,
      );
}

class LedgerModel {
  final String accountCode;
  final String accountName;
  final List<LedgerEntryModel> entries;
  final double totalDebit;
  final double totalCredit;

  const LedgerModel({
    required this.accountCode,
    required this.accountName,
    required this.entries,
    required this.totalDebit,
    required this.totalCredit,
  });

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      accountCode: json['account_code']?.toString() ?? '',
      accountName: json['account_name']?.toString() ?? '',
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => LedgerEntryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory LedgerModel.mock() {
    return LedgerModel(
      accountCode: '1-1200',
      accountName: 'Bank BCA - Operasional',
      totalDebit: 247000000,
      totalCredit: 122000000,
      entries: [
        LedgerEntryModel(
          date: DateTime(2026, 3, 1),
          code: '1-1200',
          description: 'Saldo Awal',
          ref: 'OB-2603',
          debit: 115000000,
          credit: 0,
          balance: 115000000,
        ),
        LedgerEntryModel(
          date: DateTime(2026, 3, 3),
          code: '1-1200',
          description: 'Penerimaan Pembayaran Siswa - Batch Python Bootcamp',
          ref: 'INV-2026-003',
          debit: 45000000,
          credit: 0,
          balance: 160000000,
        ),
        LedgerEntryModel(
          date: DateTime(2026, 3, 5),
          code: '1-1200',
          description: 'Pembayaran Gaji Karyawan - Maret 2026',
          ref: 'PAY-2026-015',
          debit: 0,
          credit: 45000000,
          balance: 115000000,
        ),
        LedgerEntryModel(
          date: DateTime(2026, 3, 8),
          code: '1-1200',
          description: 'Penerimaan Pembayaran Siswa - Batch UI/UX Design',
          ref: 'INV-2026-008',
          debit: 32000000,
          credit: 0,
          balance: 147000000,
        ),
        LedgerEntryModel(
          date: DateTime(2026, 3, 10),
          code: '1-1200',
          description: 'Pembayaran Fasilitator - Ahmad Rizki',
          ref: 'FAC-2026-010',
          debit: 0,
          credit: 12000000,
          balance: 135000000,
        ),
        LedgerEntryModel(
          date: DateTime(2026, 3, 12),
          code: '1-1200',
          description: 'Penerimaan Pembayaran Siswa - Batch Data Science',
          ref: 'INV-2026-012',
          debit: 55000000,
          credit: 0,
          balance: 190000000,
        ),
        LedgerEntryModel(
          date: DateTime(2026, 3, 15),
          code: '1-1200',
          description: 'Pembayaran Sewa Gedung - Maret 2026',
          ref: 'EXP-2026-022',
          debit: 0,
          credit: 22000000,
          balance: 168000000,
        ),
        LedgerEntryModel(
          date: DateTime(2026, 3, 18),
          code: '1-1200',
          description: 'Penerimaan Pembayaran Siswa - Batch Mobile Dev',
          ref: 'INV-2026-018',
          debit: 0,
          credit: 43000000,
          balance: 125000000,
        ),
      ],
    );
  }

  LedgerEntity toEntity() => LedgerEntity(
        accountCode: accountCode,
        accountName: accountName,
        entries: entries.map((e) => e.toEntity()).toList(),
        totalDebit: totalDebit,
        totalCredit: totalCredit,
      );
}
