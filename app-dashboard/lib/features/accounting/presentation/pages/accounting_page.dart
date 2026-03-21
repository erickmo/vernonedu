import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

// ─── LOCAL DATA MODELS ───────────────────────────────────────────────────────

class _TransaksiData {
  final String id;
  final String deskripsi;
  final String kategori;
  final double jumlah;
  final bool isDebit;
  final String tanggal;
  final String status;

  const _TransaksiData({
    required this.id,
    required this.deskripsi,
    required this.kategori,
    required this.jumlah,
    required this.isDebit,
    required this.tanggal,
    required this.status,
  });
}

class _AnggaranData {
  final String kategori;
  final double realisasi;
  final double anggaran;
  final bool isPendapatan;

  const _AnggaranData(this.kategori, this.realisasi, this.anggaran, this.isPendapatan);

  double get persentase => (realisasi / anggaran * 100).clamp(0.0, 100.0);
}

class _LaporanData {
  final String judul;
  final String deskripsi;
  final IconData icon;
  final Color color;

  const _LaporanData(this.judul, this.deskripsi, this.icon, this.color);
}

// ─── MOCK DATA ───────────────────────────────────────────────────────────────

const _mockTransaksi = [
  _TransaksiData(id: 'TRX-001', deskripsi: 'Pendapatan Course Digital Marketing Batch 5', kategori: 'Pendapatan', jumlah: 15000000, isDebit: false, tanggal: '20 Mar 2026', status: 'Selesai'),
  _TransaksiData(id: 'TRX-002', deskripsi: 'Gaji Fasilitator Maret 2026', kategori: 'Gaji & SDM', jumlah: 8500000, isDebit: true, tanggal: '19 Mar 2026', status: 'Selesai'),
  _TransaksiData(id: 'TRX-003', deskripsi: 'Biaya Iklan Meta Ads', kategori: 'Marketing', jumlah: 3200000, isDebit: true, tanggal: '18 Mar 2026', status: 'Selesai'),
  _TransaksiData(id: 'TRX-004', deskripsi: 'Pendapatan Course Barbershop Batch 3', kategori: 'Pendapatan', jumlah: 9800000, isDebit: false, tanggal: '17 Mar 2026', status: 'Selesai'),
  _TransaksiData(id: 'TRX-005', deskripsi: 'Sewa Gedung Training Center', kategori: 'Operasional', jumlah: 5000000, isDebit: true, tanggal: '15 Mar 2026', status: 'Selesai'),
  _TransaksiData(id: 'TRX-006', deskripsi: 'Pendapatan Course Tata Boga Batch 7', kategori: 'Pendapatan', jumlah: 12400000, isDebit: false, tanggal: '14 Mar 2026', status: 'Selesai'),
  _TransaksiData(id: 'TRX-007', deskripsi: 'Langganan Platform LMS', kategori: 'Teknologi', jumlah: 1800000, isDebit: true, tanggal: '12 Mar 2026', status: 'Selesai'),
  _TransaksiData(id: 'TRX-008', deskripsi: 'Piutang - PT Maju Bersama', kategori: 'Piutang', jumlah: 7500000, isDebit: false, tanggal: '10 Mar 2026', status: 'Pending'),
];

const _mockAnggaran = [
  _AnggaranData('Pendapatan', 124.5, 130.0, true),
  _AnggaranData('Gaji & SDM', 45.2, 50.0, false),
  _AnggaranData('Operasional', 15.0, 18.0, false),
  _AnggaranData('Marketing', 12.5, 15.0, false),
  _AnggaranData('Teknologi', 8.0, 12.0, false),
  _AnggaranData('Lainnya', 7.5, 10.0, false),
];

const _mockLaporan = [
  _LaporanData('Laba Rugi', 'Pendapatan, pengeluaran, dan laba bersih periode berjalan', Icons.insert_chart_outlined, AppColors.success),
  _LaporanData('Neraca', 'Posisi aset, kewajiban, dan ekuitas perusahaan', Icons.balance_outlined, AppColors.primary),
  _LaporanData('Arus Kas', 'Aliran masuk dan keluar kas operasional, investasi, pendanaan', Icons.water_drop_outlined, AppColors.info),
  _LaporanData('Buku Besar', 'Rincian mutasi setiap akun dalam periode tertentu', Icons.menu_book_outlined, AppColors.secondary),
  _LaporanData('Hutang & Piutang', 'Laporan aging hutang pemasok dan piutang pelanggan', Icons.swap_horiz_outlined, Color(0xFF6A1B9A)),
  _LaporanData('Laporan Pajak', 'Rekap PPh, PPN, dan kewajiban pajak lainnya', Icons.receipt_outlined, AppColors.warning),
];

// ─── PAGE ────────────────────────────────────────────────────────────────────

class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  int _selectedTab = 0;
  String _selectedPeriod = 'Maret 2026';

  static const _periods = [
    'Oktober 2025', 'November 2025', 'Desember 2025',
    'Januari 2026', 'Februari 2026', 'Maret 2026',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AccountingHeader(
            selectedPeriod: _selectedPeriod,
            periods: _periods,
            onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
          ),
          const SizedBox(height: AppDimensions.lg),
          const _AccountingStatCards(),
          const SizedBox(height: AppDimensions.lg),
          const _AccountingChartsRow(),
          const SizedBox(height: AppDimensions.lg),
          _AccountingTabSection(
            selectedTab: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
          ),
        ],
      ),
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────

class _AccountingHeader extends StatelessWidget {
  final String selectedPeriod;
  final List<String> periods;
  final ValueChanged<String> onPeriodChanged;

  const _AccountingHeader({
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildTitle(context)),
        _buildPeriodDropdown(),
        const SizedBox(width: AppDimensions.sm),
        _buildExportButton(),
        const SizedBox(width: AppDimensions.sm),
        _buildJournalButton(),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akuntansi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          Text(
            'Keuangan, anggaran, dan laporan pembukuan',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      );

  Widget _buildPeriodDropdown() => Container(
        height: AppDimensions.buttonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedPeriod,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            icon: const Icon(Icons.expand_more, size: 18, color: AppColors.textSecondary),
            onChanged: (v) { if (v != null) onPeriodChanged(v); },
            items: periods
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
          ),
        ),
      );

  Widget _buildExportButton() => OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.download_outlined, size: 16),
        label: const Text('Ekspor'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
        ),
      );

  Widget _buildJournalButton() => ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Jurnal Baru'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
        ),
      );
}

// ─── STAT CARDS ──────────────────────────────────────────────────────────────

class _AccountingStatCards extends StatelessWidget {
  const _AccountingStatCards();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxis = constraints.maxWidth > 1100 ? 3 : constraints.maxWidth > 700 ? 2 : 1;
        return GridView.count(
          crossAxisCount: crossAxis,
          crossAxisSpacing: AppDimensions.md,
          mainAxisSpacing: AppDimensions.md,
          childAspectRatio: 2.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _StatNumberCard(
              label: 'Total Pendapatan',
              value: 'Rp 124,5M',
              delta: '+8,2%',
              deltaPositive: true,
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
            ),
            _StatNumberCard(
              label: 'Total Pengeluaran',
              value: 'Rp 68,3M',
              delta: '+3,1%',
              deltaPositive: false,
              icon: Icons.trending_down_rounded,
              color: AppColors.warning,
            ),
            _StatNumberCard(
              label: 'Laba Bersih',
              value: 'Rp 56,2M',
              delta: '+14,7%',
              deltaPositive: true,
              icon: Icons.account_balance_outlined,
              color: AppColors.primary,
            ),
            _StatNumberCard(
              label: 'Kas & Bank',
              value: 'Rp 89,1M',
              delta: '+2,3%',
              deltaPositive: true,
              icon: Icons.savings_outlined,
              color: AppColors.info,
            ),
            _StatNumberCard(
              label: 'Piutang',
              value: 'Rp 18,6M',
              delta: '-5,4%',
              deltaPositive: true,
              icon: Icons.receipt_long_outlined,
              color: Color(0xFF6A1B9A),
            ),
            _StatNumberCard(
              label: 'Hutang',
              value: 'Rp 12,3M',
              delta: '+1,8%',
              deltaPositive: false,
              icon: Icons.credit_card_outlined,
              color: AppColors.error,
            ),
          ],
        );
      },
    );
  }
}

class _StatNumberCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final bool deltaPositive;
  final IconData icon;
  final Color color;

  const _StatNumberCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaPositive,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTopRow(),
          _buildValue(context),
          _buildDelta(),
        ],
      ),
    );
  }

  Widget _buildTopRow() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ],
      );

  Widget _buildValue(BuildContext context) => Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
      );

  Widget _buildDelta() => Row(
        children: [
          Icon(
            deltaPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: deltaPositive ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 2),
          Text(
            '$delta vs bulan lalu',
            style: TextStyle(
              fontSize: 11,
              color: deltaPositive ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}

// ─── CHARTS ROW ──────────────────────────────────────────────────────────────

class _AccountingChartsRow extends StatelessWidget {
  const _AccountingChartsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _RevenueExpenseChart()),
        SizedBox(width: AppDimensions.md),
        Expanded(flex: 2, child: _ExpenseBreakdownChart()),
      ],
    );
  }
}

class _RevenueExpenseChart extends StatelessWidget {
  const _RevenueExpenseChart();

  static const _months = ['Okt', 'Nov', 'Des', 'Jan', 'Feb', 'Mar'];
  static const _revenue = [85.0, 97.0, 91.0, 108.0, 118.0, 124.5];
  static const _expense = [52.0, 59.0, 55.0, 61.0, 65.0, 68.3];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppDimensions.lg),
          SizedBox(height: 220, child: BarChart(_buildBarData())),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              'Pendapatan vs Pengeluaran',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          _buildLegendDot(AppColors.success, 'Pendapatan'),
          const SizedBox(width: AppDimensions.md),
          _buildLegendDot(AppColors.warning, 'Pengeluaran'),
        ],
      );

  Widget _buildLegendDot(Color color, String label) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      );

  BarChartData _buildBarData() => BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 150,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: AppDimensions.radiusMd,
            getTooltipItem: (group, _, rod, rodIndex) {
              final month = _months[group.x];
              final label = rodIndex == 0 ? 'Pendapatan' : 'Pengeluaran';
              return BarTooltipItem(
                '$month · $label\nRp ${rod.toY.toStringAsFixed(1)}M',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < _months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _months[i],
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}M',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_months.length, _buildBarGroup),
      );

  BarChartGroupData _buildBarGroup(int x) => BarChartGroupData(
        x: x,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: _revenue[x],
            color: AppColors.success,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
          BarChartRodData(
            toY: _expense[x],
            color: AppColors.warning,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
}

class _ExpenseBreakdownChart extends StatefulWidget {
  const _ExpenseBreakdownChart();

  @override
  State<_ExpenseBreakdownChart> createState() => _ExpenseBreakdownChartState();
}

class _ExpenseBreakdownChartState extends State<_ExpenseBreakdownChart> {
  int _touchedIndex = -1;

  static const _categories = ['Gaji & SDM', 'Operasional', 'Marketing', 'Teknologi', 'Lainnya'];
  static const _values = [38.0, 22.0, 18.0, 12.0, 10.0];
  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFFF57F17),
    AppColors.info,
    AppColors.textHint,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Komposisi Pengeluaran',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppDimensions.lg),
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response?.touchedSection?.touchedSectionIndex ?? -1;
                    });
                  },
                ),
                sections: List.generate(_categories.length, _buildSection),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          ..._buildLegend(),
        ],
      ),
    );
  }

  PieChartSectionData _buildSection(int i) {
    final isTouched = i == _touchedIndex;
    return PieChartSectionData(
      color: _colors[i],
      value: _values[i],
      title: '${_values[i].toInt()}%',
      radius: isTouched ? 58 : 46,
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  List<Widget> _buildLegend() => List.generate(
        _categories.length,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _colors[i],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  _categories[i],
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
              Text(
                '${_values[i].toInt()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── TAB SECTION ─────────────────────────────────────────────────────────────

class _AccountingTabSection extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const _AccountingTabSection({
    required this.selectedTab,
    required this.onTabChanged,
  });

  static const _tabs = ['Transaksi Terbaru', 'Anggaran vs Realisasi', 'Laporan Keuangan'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabBar(),
          const Divider(height: 1, color: AppColors.border),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildTabBar() => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm,
        ),
        child: Row(
          children: List.generate(
            _tabs.length,
            (i) => Padding(
              padding: const EdgeInsets.only(right: AppDimensions.sm),
              child: _TabChip(
                label: _tabs[i],
                selected: selectedTab == i,
                onTap: () => onTabChanged(i),
              ),
            ),
          ),
        ),
      );

  Widget _buildContent() {
    switch (selectedTab) {
      case 0:
        return const _TransaksiTab();
      case 1:
        return const _AnggaranTab();
      case 2:
        return const _LaporanTab();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── TRANSAKSI TAB ───────────────────────────────────────────────────────────

class _TransaksiTab extends StatelessWidget {
  const _TransaksiTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTableHeader(),
        const Divider(height: 1, color: AppColors.divider),
        ..._mockTransaksi.map((t) => _TransaksiRow(data: t)),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildTableHeader() => const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text('ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text('Deskripsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
            SizedBox(
              width: 120,
              child: Text('Kategori', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
            SizedBox(
              width: 130,
              child: Text('Jumlah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.right),
            ),
            SizedBox(
              width: 110,
              child: Text('Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
            ),
            SizedBox(
              width: 80,
              child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center),
            ),
          ],
        ),
      );

  Widget _buildFooter(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Menampilkan 8 dari 124 transaksi',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
}

class _TransaksiRow extends StatelessWidget {
  final _TransaksiData data;

  const _TransaksiRow({required this.data});

  static String _formatRupiah(double amount) {
    if (amount >= 1000000000) return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    if (amount >= 1000000) return 'Rp ${(amount / 1000000).toStringAsFixed(1)}Jt';
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              data.id,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              data.deskripsi,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 120, child: _buildKategoriChip()),
          SizedBox(width: 130, child: _buildJumlah()),
          SizedBox(
            width: 110,
            child: Text(
              data.tanggal,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 80, child: _buildStatus()),
        ],
      ),
    );
  }

  Widget _buildKategoriChip() => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(
          data.kategori,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      );

  Widget _buildJumlah() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${data.isDebit ? '-' : '+'}${_formatRupiah(data.jumlah)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: data.isDebit ? AppColors.error : AppColors.success,
            ),
          ),
        ],
      );

  Widget _buildStatus() {
    final isSelesai = data.status == 'Selesai';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelesai ? AppColors.successSurface : AppColors.warningSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
        ),
        child: Text(
          data.status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelesai ? AppColors.success : AppColors.warning,
          ),
        ),
      ),
    );
  }
}

// ─── ANGGARAN TAB ─────────────────────────────────────────────────────────────

class _AnggaranTab extends StatelessWidget {
  const _AnggaranTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryRow(context),
          const SizedBox(height: AppDimensions.lg),
          ..._mockAnggaran.map((item) => _AnggaranItem(data: item)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context) => Row(
        children: [
          _buildSummaryCard(context, 'Total Anggaran', 'Rp 235Jt', AppColors.primary),
          const SizedBox(width: AppDimensions.md),
          _buildSummaryCard(context, 'Terpakai', 'Rp 212,7Jt', AppColors.success),
          const SizedBox(width: AppDimensions.md),
          _buildSummaryCard(context, 'Sisa Anggaran', 'Rp 22,3Jt', AppColors.warning),
        ],
      );

  Widget _buildSummaryCard(BuildContext context, String label, String value, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: AppDimensions.xs),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      );
}

class _AnggaranItem extends StatelessWidget {
  final _AnggaranData data;

  const _AnggaranItem({required this.data});

  Color _progressColor() {
    if (data.isPendapatan) {
      return data.persentase >= 90 ? AppColors.success : AppColors.warning;
    }
    if (data.persentase >= 90) return AppColors.error;
    if (data.persentase >= 75) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final color = _progressColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.kategori,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  Text(
                    'Rp ${data.realisasi.toStringAsFixed(1)}Jt',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    ' / Rp ${data.anggaran.toStringAsFixed(0)}Jt',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      '${data.persentase.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            child: LinearProgressIndicator(
              value: data.persentase / 100,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LAPORAN TAB ─────────────────────────────────────────────────────────────

class _LaporanTab extends StatelessWidget {
  const _LaporanTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxis = constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 500 ? 2 : 1;
          return GridView.count(
            crossAxisCount: crossAxis,
            crossAxisSpacing: AppDimensions.md,
            mainAxisSpacing: AppDimensions.md,
            childAspectRatio: 2.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _mockLaporan.map((l) => _LaporanCard(data: l)).toList(),
          );
        },
      ),
    );
  }
}

class _LaporanCard extends StatelessWidget {
  final _LaporanData data;

  const _LaporanCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: data.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.judul,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: data.color),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.deskripsi,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
