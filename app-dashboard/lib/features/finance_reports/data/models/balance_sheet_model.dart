import '../../domain/entities/balance_sheet_entity.dart';

class BalanceSheetAccountModel {
  final String code;
  final String name;
  final double amount;
  final bool isNegative;
  final List<BalanceSheetAccountModel> children;

  const BalanceSheetAccountModel({
    required this.code,
    required this.name,
    required this.amount,
    this.isNegative = false,
    this.children = const [],
  });

  factory BalanceSheetAccountModel.fromJson(Map<String, dynamic> json) {
    return BalanceSheetAccountModel(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isNegative: json['is_negative'] as bool? ?? false,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => BalanceSheetAccountModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  BalanceSheetAccountEntity toEntity() => BalanceSheetAccountEntity(
        code: code,
        name: name,
        amount: amount,
        isNegative: isNegative,
        children: children.map((c) => c.toEntity()).toList(),
      );
}

class BalanceSheetSectionModel {
  final String name;
  final double total;
  final List<BalanceSheetAccountModel> accounts;

  const BalanceSheetSectionModel({
    required this.name,
    required this.total,
    required this.accounts,
  });

  factory BalanceSheetSectionModel.fromJson(Map<String, dynamic> json) {
    return BalanceSheetSectionModel(
      name: json['name']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      accounts: (json['accounts'] as List<dynamic>?)
              ?.map((e) => BalanceSheetAccountModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  BalanceSheetSectionEntity toEntity() => BalanceSheetSectionEntity(
        name: name,
        total: total,
        accounts: accounts.map((a) => a.toEntity()).toList(),
      );
}

class BalanceSheetModel {
  final List<BalanceSheetSectionModel> assetSections;
  final List<BalanceSheetSectionModel> liabilitySections;
  final List<BalanceSheetSectionModel> equitySections;
  final double totalAssets;
  final double totalLiabilitiesAndEquity;

  const BalanceSheetModel({
    required this.assetSections,
    required this.liabilitySections,
    required this.equitySections,
    required this.totalAssets,
    required this.totalLiabilitiesAndEquity,
  });

  factory BalanceSheetModel.fromJson(Map<String, dynamic> json) {
    return BalanceSheetModel(
      assetSections: (json['asset_sections'] as List<dynamic>?)
              ?.map((e) => BalanceSheetSectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      liabilitySections: (json['liability_sections'] as List<dynamic>?)
              ?.map((e) => BalanceSheetSectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      equitySections: (json['equity_sections'] as List<dynamic>?)
              ?.map((e) => BalanceSheetSectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAssets: (json['total_assets'] as num?)?.toDouble() ?? 0.0,
      totalLiabilitiesAndEquity:
          (json['total_liabilities_and_equity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory BalanceSheetModel.mock() {
    return const BalanceSheetModel(
      assetSections: [
        BalanceSheetSectionModel(
          name: 'Aset Lancar',
          total: 285000000,
          accounts: [
            BalanceSheetAccountModel(code: '1-1100', name: 'Kas', amount: 45000000),
            BalanceSheetAccountModel(
                code: '1-1200', name: 'Bank BCA - Operasional', amount: 125000000),
            BalanceSheetAccountModel(
                code: '1-1300', name: 'Piutang Usaha', amount: 85000000),
            BalanceSheetAccountModel(
                code: '1-1400', name: 'Biaya Dibayar Dimuka', amount: 30000000),
          ],
        ),
        BalanceSheetSectionModel(
          name: 'Aset Tetap',
          total: 195000000,
          accounts: [
            BalanceSheetAccountModel(
                code: '1-2100', name: 'Peralatan Komputer', amount: 120000000),
            BalanceSheetAccountModel(
                code: '1-2200', name: 'Furniture & Perlengkapan', amount: 75000000),
            BalanceSheetAccountModel(
                code: '1-2900',
                name: 'Akumulasi Penyusutan',
                amount: -45000000,
                isNegative: true),
          ],
        ),
      ],
      liabilitySections: [
        BalanceSheetSectionModel(
          name: 'Kewajiban Jangka Pendek',
          total: 95000000,
          accounts: [
            BalanceSheetAccountModel(
                code: '2-1100', name: 'Hutang Usaha', amount: 35000000),
            BalanceSheetAccountModel(
                code: '2-1200', name: 'Biaya Yang Masih Harus Dibayar', amount: 25000000),
            BalanceSheetAccountModel(
                code: '2-1300', name: 'Pendapatan Diterima Dimuka', amount: 35000000),
          ],
        ),
        BalanceSheetSectionModel(
          name: 'Kewajiban Jangka Panjang',
          total: 50000000,
          accounts: [
            BalanceSheetAccountModel(
                code: '2-2100', name: 'Hutang Bank Jangka Panjang', amount: 50000000),
          ],
        ),
      ],
      equitySections: [
        BalanceSheetSectionModel(
          name: 'Ekuitas',
          total: 290000000,
          accounts: [
            BalanceSheetAccountModel(
                code: '3-1000', name: 'Modal Disetor', amount: 200000000),
            BalanceSheetAccountModel(
                code: '3-2000', name: 'Laba Ditahan', amount: 65000000),
            BalanceSheetAccountModel(
                code: '3-3000', name: 'Laba Tahun Berjalan', amount: 25000000),
          ],
        ),
      ],
      totalAssets: 435000000,
      totalLiabilitiesAndEquity: 435000000,
    );
  }

  BalanceSheetEntity toEntity() => BalanceSheetEntity(
        assetSections: assetSections.map((s) => s.toEntity()).toList(),
        liabilitySections: liabilitySections.map((s) => s.toEntity()).toList(),
        equitySections: equitySections.map((s) => s.toEntity()).toList(),
        totalAssets: totalAssets,
        totalLiabilitiesAndEquity: totalLiabilitiesAndEquity,
      );
}
