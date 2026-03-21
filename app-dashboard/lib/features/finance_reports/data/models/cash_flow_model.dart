import '../../domain/entities/cash_flow_entity.dart';

class CashFlowLineModel {
  final String name;
  final double amount;
  final bool isSubtotal;

  const CashFlowLineModel({
    required this.name,
    required this.amount,
    this.isSubtotal = false,
  });

  factory CashFlowLineModel.fromJson(Map<String, dynamic> json) {
    return CashFlowLineModel(
      name: json['name']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isSubtotal: json['is_subtotal'] as bool? ?? false,
    );
  }

  CashFlowLineEntity toEntity() =>
      CashFlowLineEntity(name: name, amount: amount, isSubtotal: isSubtotal);
}

class CashFlowSectionModel {
  final String name;
  final List<CashFlowLineModel> lines;
  final double netCash;

  const CashFlowSectionModel({
    required this.name,
    required this.lines,
    required this.netCash,
  });

  factory CashFlowSectionModel.fromJson(Map<String, dynamic> json) {
    return CashFlowSectionModel(
      name: json['name']?.toString() ?? '',
      lines: (json['lines'] as List<dynamic>?)
              ?.map((e) => CashFlowLineModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      netCash: (json['net_cash'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CashFlowSectionEntity toEntity() => CashFlowSectionEntity(
        name: name,
        lines: lines.map((l) => l.toEntity()).toList(),
        netCash: netCash,
      );
}

class MonthlyCashPointModel {
  final String label;
  final double balance;

  const MonthlyCashPointModel({required this.label, required this.balance});

  factory MonthlyCashPointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyCashPointModel(
      label: json['label']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  MonthlyCashPoint toEntity() => MonthlyCashPoint(label: label, balance: balance);
}

class CashFlowModel {
  final CashFlowSectionModel operating;
  final CashFlowSectionModel investing;
  final CashFlowSectionModel financing;
  final double netChange;
  final double openingBalance;
  final double closingBalance;
  final List<MonthlyCashPointModel> monthlyTrend;

  const CashFlowModel({
    required this.operating,
    required this.investing,
    required this.financing,
    required this.netChange,
    required this.openingBalance,
    required this.closingBalance,
    this.monthlyTrend = const [],
  });

  factory CashFlowModel.fromJson(Map<String, dynamic> json) {
    return CashFlowModel(
      operating: CashFlowSectionModel.fromJson(
          json['operating'] as Map<String, dynamic>? ?? {}),
      investing: CashFlowSectionModel.fromJson(
          json['investing'] as Map<String, dynamic>? ?? {}),
      financing: CashFlowSectionModel.fromJson(
          json['financing'] as Map<String, dynamic>? ?? {}),
      netChange: (json['net_change'] as num?)?.toDouble() ?? 0.0,
      openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      closingBalance: (json['closing_balance'] as num?)?.toDouble() ?? 0.0,
      monthlyTrend: (json['monthly_trend'] as List<dynamic>?)
              ?.map((e) => MonthlyCashPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory CashFlowModel.mock() {
    return const CashFlowModel(
      operating: CashFlowSectionModel(
        name: 'Aktivitas Operasi',
        netCash: 85000000,
        lines: [
          CashFlowLineModel(name: 'Penerimaan dari Siswa', amount: 195000000),
          CashFlowLineModel(name: 'Penerimaan Lain-lain', amount: 12000000),
          CashFlowLineModel(
              name: 'Pembayaran Fasilitator & Tenaga Pengajar', amount: -55000000),
          CashFlowLineModel(name: 'Pembayaran Gaji Karyawan', amount: -45000000),
          CashFlowLineModel(
              name: 'Pembayaran Sewa & Utilitas', amount: -22000000),
          CashFlowLineModel(name: 'Net Kas dari Aktivitas Operasi',
              amount: 85000000, isSubtotal: true),
        ],
      ),
      investing: CashFlowSectionModel(
        name: 'Aktivitas Investasi',
        netCash: -18000000,
        lines: [
          CashFlowLineModel(
              name: 'Pembelian Peralatan Komputer', amount: -15000000),
          CashFlowLineModel(name: 'Pembelian Furniture', amount: -3000000),
          CashFlowLineModel(name: 'Net Kas dari Aktivitas Investasi',
              amount: -18000000, isSubtotal: true),
        ],
      ),
      financing: CashFlowSectionModel(
        name: 'Aktivitas Pendanaan',
        netCash: -12000000,
        lines: [
          CashFlowLineModel(name: 'Pembayaran Cicilan Bank', amount: -12000000),
          CashFlowLineModel(name: 'Net Kas dari Aktivitas Pendanaan',
              amount: -12000000, isSubtotal: true),
        ],
      ),
      netChange: 55000000,
      openingBalance: 115000000,
      closingBalance: 170000000,
      monthlyTrend: [
        MonthlyCashPointModel(label: 'Okt 25', balance: 95000000),
        MonthlyCashPointModel(label: 'Nov 25', balance: 115000000),
        MonthlyCashPointModel(label: 'Des 25', balance: 130000000),
        MonthlyCashPointModel(label: 'Jan 26', balance: 115000000),
        MonthlyCashPointModel(label: 'Feb 26', balance: 145000000),
        MonthlyCashPointModel(label: 'Mar 26', balance: 170000000),
      ],
    );
  }

  CashFlowEntity toEntity() => CashFlowEntity(
        operating: operating.toEntity(),
        investing: investing.toEntity(),
        financing: financing.toEntity(),
        netChange: netChange,
        openingBalance: openingBalance,
        closingBalance: closingBalance,
        monthlyTrend: monthlyTrend.map((p) => p.toEntity()).toList(),
      );
}
