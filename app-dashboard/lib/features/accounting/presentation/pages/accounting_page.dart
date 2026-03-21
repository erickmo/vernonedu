import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/accounting_stats_entity.dart';
import '../../domain/entities/budget_item_entity.dart';
import '../../domain/entities/coa_entity.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../cubit/accounting_cubit.dart';

// ─── PAGE ────────────────────────────────────────────────────────────────────

class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late AccountingCubit _cubit;

  static const _monthNames = [
    '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  List<String> get _periods {
    final now = DateTime.now();
    final result = <String>[];
    for (int i = 11; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i);
      result.add('${_monthNames[d.month]} ${d.year}');
    }
    return result;
  }

  String get _selectedPeriod => '${_monthNames[_selectedMonth]} $_selectedYear';

  void _onPeriodChanged(String period) {
    final parts = period.split(' ');
    final month = _monthNames.indexOf(parts[0]);
    final year = int.parse(parts[1]);
    setState(() {
      _selectedMonth = month;
      _selectedYear = year;
    });
    _cubit.loadAll(month: month, year: year);
  }

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AccountingCubit>()..loadAll(month: _selectedMonth, year: _selectedYear);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<AccountingCubit, AccountingState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AccountingHeader(
                  selectedPeriod: _selectedPeriod,
                  periods: _periods,
                  onPeriodChanged: _onPeriodChanged,
                  coa: state is AccountingLoaded ? state.coa : const [],
                ),
                const SizedBox(height: AppDimensions.lg),
                if (state is AccountingLoading)
                  const _LoadingSection()
                else if (state is AccountingError)
                  _ErrorSection(message: state.message, onRetry: () => _cubit.loadAll(month: _selectedMonth, year: _selectedYear))
                else if (state is AccountingLoaded) ...[
                  _AccountingStatCards(stats: state.stats),
                  const SizedBox(height: AppDimensions.lg),
                  _AccountingChartsRow(transactions: state.transactions, stats: state.stats),
                  const SizedBox(height: AppDimensions.lg),
                  _AccountingTabSection(
                    transactions: state.transactions,
                    budgetItems: state.budgetItems,
                    invoices: state.invoices,
                    coa: state.coa,
                  ),
                ] else
                  const _LoadingSection(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── LOADING / ERROR ─────────────────────────────────────────────────────────

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(64), child: CircularProgressIndicator()));
}

class _ErrorSection extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorSection({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppDimensions.md),
              Text(message, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppDimensions.md),
              ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
}

// ─── HEADER ──────────────────────────────────────────────────────────────────

class _AccountingHeader extends StatelessWidget {
  final String selectedPeriod;
  final List<String> periods;
  final ValueChanged<String> onPeriodChanged;
  final List<CoaEntity> coa;

  const _AccountingHeader({
    required this.selectedPeriod,
    required this.periods,
    required this.onPeriodChanged,
    required this.coa,
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
        _buildJournalButton(context),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Akuntansi', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text('Keuangan, anggaran, dan laporan pembukuan', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
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
            items: periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
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
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
        ),
      );

  Widget _buildJournalButton(BuildContext context) => ElevatedButton.icon(
        onPressed: () => _showCreateTransactionDialog(context),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Jurnal Baru'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
        ),
      );

  void _showCreateTransactionDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => _CreateTransactionDialog(coa: coa, cubit: context.read<AccountingCubit>()));
  }
}

// ─── CREATE TRANSACTION DIALOG ───────────────────────────────────────────────

class _CreateTransactionDialog extends StatefulWidget {
  final List<CoaEntity> coa;
  final AccountingCubit cubit;
  const _CreateTransactionDialog({required this.coa, required this.cubit});

  @override
  State<_CreateTransactionDialog> createState() => _CreateTransactionDialogState();
}

class _CreateTransactionDialogState extends State<_CreateTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  String _type = 'income';
  String _category = 'Pendapatan Course';
  String _debitCode = '';
  String _creditCode = '';
  bool _loading = false;

  static const _categories = ['Pendapatan Course', 'Gaji & SDM', 'Marketing', 'Operasional', 'Teknologi', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toIso8601String().split('T')[0];
    if (widget.coa.isNotEmpty) {
      _debitCode = widget.coa.first.code;
      _creditCode = widget.coa.first.code;
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Jurnal', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: AppDimensions.md),
              Row(children: [
                Expanded(child: _buildTypeDropdown()),
                const SizedBox(width: AppDimensions.md),
                Expanded(child: _buildCategoryDropdown()),
              ]),
              const SizedBox(height: AppDimensions.md),
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Jumlah (Rp)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (double.tryParse(v) == null) return 'Angka tidak valid';
                    return null;
                  },
                )),
                const SizedBox(width: AppDimensions.md),
                Expanded(child: TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                )),
              ]),
              if (widget.coa.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.md),
                Row(children: [
                  Expanded(child: _buildCoaDropdown('Akun Debit', _debitCode, (v) => setState(() => _debitCode = v!))),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(child: _buildCoaDropdown('Akun Kredit', _creditCode, (v) => setState(() => _creditCode = v!))),
                ]),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() => DropdownButtonFormField<String>(
        value: _type,
        decoration: const InputDecoration(labelText: 'Tipe', border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
          DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
          DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
        ],
        onChanged: (v) => setState(() => _type = v!),
      );

  Widget _buildCategoryDropdown() => DropdownButtonFormField<String>(
        value: _category,
        decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) => setState(() => _category = v!),
      );

  Widget _buildCoaDropdown(String label, String value, ValueChanged<String?> onChanged) {
    final items = widget.coa.where((c) => c.parentCode.isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final safeValue = items.any((c) => c.code == value) ? value : items.first.code;
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((c) => DropdownMenuItem(value: c.code, child: Text('${c.code} ${c.name}', overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final body = <String, dynamic>{
      'description': _descController.text,
      'transaction_type': _type,
      'amount': double.parse(_amountController.text),
      'category': _category,
      'transaction_date': _dateController.text,
      'status': 'completed',
      if (_debitCode.isNotEmpty) 'debit_account_code': _debitCode,
      if (_creditCode.isNotEmpty) 'credit_account_code': _creditCode,
    };
    final ok = await widget.cubit.createTransaction(body: body);
    if (mounted) {
      setState(() => _loading = false);
      if (ok) Navigator.pop(context);
    }
  }
}

// ─── STAT CARDS ──────────────────────────────────────────────────────────────

class _AccountingStatCards extends StatelessWidget {
  final AccountingStatsEntity stats;
  const _AccountingStatCards({required this.stats});

  static String _fmt(double v) {
    if (v >= 1000000000) return 'Rp ${(v / 1000000000).toStringAsFixed(1)}M';
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      (label: 'Total Pendapatan', value: _fmt(stats.totalRevenue), icon: Icons.trending_up_rounded, color: AppColors.success),
      (label: 'Total Pengeluaran', value: _fmt(stats.totalExpense), icon: Icons.trending_down_rounded, color: AppColors.warning),
      (label: 'Laba Bersih', value: _fmt(stats.netProfit), icon: Icons.account_balance_outlined, color: AppColors.primary),
      (label: 'Kas & Bank', value: _fmt(stats.cashAndBank), icon: Icons.savings_outlined, color: AppColors.info),
      (label: 'Piutang', value: _fmt(stats.receivables), icon: Icons.receipt_long_outlined, color: const Color(0xFF6A1B9A)),
      (label: 'Hutang', value: _fmt(stats.payables), icon: Icons.credit_card_outlined, color: AppColors.error),
    ];
    return LayoutBuilder(builder: (ctx, c) {
      final crossAxis = c.maxWidth > 1100 ? 3 : c.maxWidth > 700 ? 2 : 1;
      return GridView.count(
        crossAxisCount: crossAxis,
        crossAxisSpacing: AppDimensions.md,
        mainAxisSpacing: AppDimensions.md,
        childAspectRatio: 2.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards.map((c) => _StatCard(label: c.label, value: c.value, icon: c.icon, color: c.color)).toList(),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                child: Icon(icon, size: 16, color: color),
              ),
            ]),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
          ],
        ),
      );
}

// ─── CHARTS ROW ──────────────────────────────────────────────────────────────

class _AccountingChartsRow extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final AccountingStatsEntity stats;
  const _AccountingChartsRow({required this.transactions, required this.stats});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _RevenueExpenseChart(stats: stats)),
          const SizedBox(width: AppDimensions.md),
          Expanded(flex: 2, child: _ExpenseBreakdownChart(transactions: transactions)),
        ],
      );
}

class _RevenueExpenseChart extends StatelessWidget {
  final AccountingStatsEntity stats;
  const _RevenueExpenseChart({required this.stats});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('Pendapatan vs Pengeluaran', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
              _dot(AppColors.success, 'Pendapatan'),
              const SizedBox(width: AppDimensions.md),
              _dot(AppColors.warning, 'Pengeluaran'),
            ]),
            const SizedBox(height: AppDimensions.lg),
            SizedBox(height: 220, child: BarChart(_buildBarData())),
          ],
        ),
      );

  Widget _dot(Color c, String label) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]);

  BarChartData _buildBarData() {
    final revenue = stats.totalRevenue / 1000000;
    final expense = stats.totalExpense / 1000000;
    final maxY = (revenue > expense ? revenue : expense) * 1.3;
    return BarChartData(
      alignment: BarChartAlignment.center,
      maxY: maxY > 0 ? maxY : 10,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: AppDimensions.radiusMd,
          getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
            '${rodIndex == 0 ? 'Pendapatan' : 'Pengeluaran'}\nRp ${rod.toY.toStringAsFixed(1)}Jt',
            const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (v, _) => Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(v == 0 ? 'Periode Ini' : '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 44,
          getTitlesWidget: (v, _) => Text('${v.toInt()}Jt', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        )),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      barGroups: [
        BarChartGroupData(x: 0, barsSpace: 8, barRods: [
          BarChartRodData(toY: revenue, color: AppColors.success, width: 32, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          BarChartRodData(toY: expense, color: AppColors.warning, width: 32, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
        ]),
      ],
    );
  }
}

class _ExpenseBreakdownChart extends StatefulWidget {
  final List<TransactionEntity> transactions;
  const _ExpenseBreakdownChart({required this.transactions});
  @override
  State<_ExpenseBreakdownChart> createState() => _ExpenseBreakdownChartState();
}

class _ExpenseBreakdownChartState extends State<_ExpenseBreakdownChart> {
  int _touchedIndex = -1;

  static const _palette = [AppColors.primary, AppColors.secondary, Color(0xFFF57F17), AppColors.info, AppColors.textHint, Color(0xFF6A1B9A)];

  Map<String, double> _expenseByCategory() {
    final map = <String, double>{};
    for (final t in widget.transactions) {
      if (t.transactionType == 'expense') {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final categoryMap = _expenseByCategory();
    final categories = categoryMap.keys.toList();
    final total = categoryMap.values.fold(0.0, (a, b) => a + b);

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
          Text('Komposisi Pengeluaran', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDimensions.lg),
          if (categories.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Tidak ada data', style: TextStyle(color: AppColors.textSecondary))))
          else ...[
            SizedBox(
              height: 160,
              child: PieChart(PieChartData(
                pieTouchData: PieTouchData(touchCallback: (_, r) => setState(() => _touchedIndex = r?.touchedSection?.touchedSectionIndex ?? -1)),
                sections: List.generate(categories.length, (i) {
                  final pct = total > 0 ? (categoryMap[categories[i]]! / total * 100) : 0.0;
                  return PieChartSectionData(
                    color: _palette[i % _palette.length],
                    value: categoryMap[categories[i]],
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: i == _touchedIndex ? 58 : 46,
                    titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  );
                }),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              )),
            ),
            const SizedBox(height: AppDimensions.md),
            ...List.generate(categories.length, (i) {
              final pct = total > 0 ? (categoryMap[categories[i]]! / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _palette[i % _palette.length], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(child: Text(categories[i], style: const TextStyle(fontSize: 12, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                  Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ]),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── TAB SECTION ─────────────────────────────────────────────────────────────

class _AccountingTabSection extends StatefulWidget {
  final List<TransactionEntity> transactions;
  final List<BudgetItemEntity> budgetItems;
  final List<InvoiceEntity> invoices;
  final List<CoaEntity> coa;

  const _AccountingTabSection({
    required this.transactions,
    required this.budgetItems,
    required this.invoices,
    required this.coa,
  });

  @override
  State<_AccountingTabSection> createState() => _AccountingTabSectionState();
}

class _AccountingTabSectionState extends State<_AccountingTabSection> {
  int _selectedTab = 0;

  static const _tabs = ['Transaksi', 'Anggaran vs Realisasi', 'Faktur', 'Buku Besar'];

  @override
  Widget build(BuildContext context) => Container(
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

  Widget _buildTabBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
        child: Row(
          children: List.generate(_tabs.length, (i) => Padding(
            padding: const EdgeInsets.only(right: AppDimensions.sm),
            child: _TabChip(label: _tabs[i], selected: _selectedTab == i, onTap: () => setState(() => _selectedTab = i)),
          )),
        ),
      );

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0: return _TransaksiTab(transactions: widget.transactions);
      case 1: return _AnggaranTab(budgetItems: widget.budgetItems);
      case 2: return _FakturTab(invoices: widget.invoices);
      case 3: return _CoaTab(coa: widget.coa);
      default: return const SizedBox.shrink();
    }
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.xs + 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? AppColors.textOnPrimary : AppColors.textSecondary)),
        ),
      );
}

// ─── TRANSAKSI TAB ────────────────────────────────────────────────────────────

class _TransaksiTab extends StatelessWidget {
  final List<TransactionEntity> transactions;
  const _TransaksiTab({required this.transactions});

  static String _fmt(double amount) {
    if (amount >= 1000000000) return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    if (amount >= 1000000) return 'Rp ${(amount / 1000000).toStringAsFixed(1)}Jt';
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: Text('Tidak ada transaksi untuk periode ini', style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    return Column(children: [
      _buildHeader(),
      const Divider(height: 1, color: AppColors.divider),
      ...transactions.map((t) => _buildRow(t)),
    ]);
  }

  Widget _buildHeader() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
        child: Row(children: [
          SizedBox(width: 110, child: Text('Referensi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(child: Text('Deskripsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          SizedBox(width: 120, child: Text('Kategori', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          SizedBox(width: 130, child: Text('Jumlah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.right)),
          SizedBox(width: 110, child: Text('Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center)),
          SizedBox(width: 80, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center)),
        ]),
      );

  Widget _buildRow(TransactionEntity t) {
    final isIncome = t.transactionType == 'income';
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
      child: Row(children: [
        SizedBox(width: 110, child: Text(t.referenceNumber.isNotEmpty ? t.referenceNumber : '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        Expanded(child: Text(t.description, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        SizedBox(width: 120, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: 2),
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
          child: Text(t.category, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
        )),
        SizedBox(width: 130, child: Text(
          '${isIncome ? '+' : '-'}${_fmt(t.amount)}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isIncome ? AppColors.success : AppColors.error),
          textAlign: TextAlign.right,
        )),
        SizedBox(width: 110, child: Text(t.transactionDate.length > 10 ? t.transactionDate.substring(0, 10) : t.transactionDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center)),
        SizedBox(width: 80, child: Center(child: _statusBadge(t.status))),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    final (bg, fg) = switch (status) {
      'completed' => (AppColors.successSurface, AppColors.success),
      'draft' => (AppColors.surfaceVariant, AppColors.textSecondary),
      _ => (AppColors.warningSurface, AppColors.warning),
    };
    final label = switch (status) {
      'completed' => 'Selesai',
      'draft' => 'Draft',
      'cancelled' => 'Batal',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppDimensions.radiusCircle)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

// ─── ANGGARAN TAB ─────────────────────────────────────────────────────────────

class _AnggaranTab extends StatelessWidget {
  final List<BudgetItemEntity> budgetItems;
  const _AnggaranTab({required this.budgetItems});

  static String _fmt(double v) => v >= 1000000 ? 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt' : 'Rp ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (budgetItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: Text('Belum ada data anggaran untuk periode ini', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final totalAnggaran = budgetItems.where((b) => !b.isPendapatan).fold(0.0, (s, b) => s + b.anggaran);
    final totalRealisasi = budgetItems.where((b) => !b.isPendapatan).fold(0.0, (s, b) => s + b.realisasi);

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _summaryCard('Total Anggaran', _fmt(totalAnggaran), AppColors.primary),
            const SizedBox(width: AppDimensions.md),
            _summaryCard('Terpakai', _fmt(totalRealisasi), AppColors.success),
            const SizedBox(width: AppDimensions.md),
            _summaryCard('Sisa', _fmt((totalAnggaran - totalRealisasi).clamp(0, double.infinity)), AppColors.warning),
          ]),
          const SizedBox(height: AppDimensions.lg),
          ...budgetItems.map((item) => _AnggaranItem(data: item)),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: AppDimensions.xs),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          ]),
        ),
      );
}

class _AnggaranItem extends StatelessWidget {
  final BudgetItemEntity data;
  const _AnggaranItem({required this.data});

  Color _progressColor() {
    if (data.isPendapatan) return data.persentase >= 90 ? AppColors.success : AppColors.warning;
    if (data.persentase >= 90) return AppColors.error;
    if (data.persentase >= 75) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final color = _progressColor();
    final realisasiStr = data.realisasi >= 1000000 ? 'Rp ${(data.realisasi / 1000000).toStringAsFixed(1)}Jt' : 'Rp ${data.realisasi.toStringAsFixed(0)}';
    final anggaranStr = data.anggaran >= 1000000 ? 'Rp ${(data.anggaran / 1000000).toStringAsFixed(0)}Jt' : 'Rp ${data.anggaran.toStringAsFixed(0)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(data.category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Row(children: [
            Text(realisasiStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text(' / $anggaranStr', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: AppDimensions.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
              child: Text('${data.persentase.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ),
          ]),
        ]),
        const SizedBox(height: AppDimensions.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          child: LinearProgressIndicator(value: data.persentase / 100, backgroundColor: AppColors.surfaceVariant, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8),
        ),
      ]),
    );
  }
}

// ─── FAKTUR TAB ───────────────────────────────────────────────────────────────

class _FakturTab extends StatelessWidget {
  final List<InvoiceEntity> invoices;
  const _FakturTab({required this.invoices});

  static String _fmt(double v) => v >= 1000000 ? 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt' : 'Rp ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: Text('Tidak ada faktur untuk periode ini', style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    return Column(children: [
      _buildHeader(),
      const Divider(height: 1, color: AppColors.divider),
      ...invoices.map((inv) => _buildRow(context, inv)),
    ]);
  }

  Widget _buildHeader() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
        child: Row(children: [
          SizedBox(width: 120, child: Text('No. Faktur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(child: Text('Siswa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          SizedBox(width: 160, child: Text('Batch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          SizedBox(width: 120, child: Text('Metode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          SizedBox(width: 120, child: Text('Jumlah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.right)),
          SizedBox(width: 110, child: Text('Jatuh Tempo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center)),
          SizedBox(width: 90, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary), textAlign: TextAlign.center)),
        ]),
      );

  Widget _buildRow(BuildContext context, InvoiceEntity inv) => Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
        child: Row(children: [
          SizedBox(width: 120, child: Text(inv.invoiceNumber.isNotEmpty ? inv.invoiceNumber : '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(child: Text(inv.studentName.isNotEmpty ? inv.studentName : '—', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 160, child: Text(inv.batchName.isNotEmpty ? inv.batchName : '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 120, child: Text(inv.paymentMethod.isNotEmpty ? inv.paymentMethod : '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          SizedBox(width: 120, child: Text(_fmt(inv.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          SizedBox(width: 110, child: Text(inv.dueDate.isNotEmpty ? inv.dueDate.substring(0, 10) : '—', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center)),
          SizedBox(width: 90, child: Center(child: _InvoiceStatusBadge(invoiceId: inv.id, status: inv.status))),
        ]),
      );
}

class _InvoiceStatusBadge extends StatelessWidget {
  final String invoiceId;
  final String status;
  const _InvoiceStatusBadge({required this.invoiceId, required this.status});

  static (Color, Color) _colors(String s) => switch (s) {
        'paid' => (AppColors.successSurface, AppColors.success),
        'sent' => (AppColors.infoSurface, AppColors.info),
        'overdue' => (AppColors.errorSurface, AppColors.error),
        'cancelled' => (AppColors.surfaceVariant, AppColors.textSecondary),
        _ => (AppColors.warningSurface, AppColors.warning),
      };

  static String _label(String s) => switch (s) {
        'paid' => 'Lunas',
        'sent' => 'Terkirim',
        'overdue' => 'Jatuh Tempo',
        'draft' => 'Draft',
        'cancelled' => 'Batal',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    return GestureDetector(
      onTap: () => _showStatusMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppDimensions.radiusCircle)),
        child: Text(_label(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    const statuses = ['draft', 'sent', 'paid', 'overdue', 'cancelled'];
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(0, 0, 0, 0),
      items: statuses.map((s) => PopupMenuItem(value: s, child: Text(_label(s)))).toList(),
    ).then((newStatus) {
      if (newStatus != null && newStatus != status) {
        context.read<AccountingCubit>().updateInvoiceStatus(id: invoiceId, status: newStatus);
      }
    });
  }
}

// ─── COA TAB ──────────────────────────────────────────────────────────────────

class _CoaTab extends StatelessWidget {
  final List<CoaEntity> coa;
  const _CoaTab({required this.coa});

  static const _typeLabels = {
    'asset': 'Aset',
    'liability': 'Kewajiban',
    'equity': 'Ekuitas',
    'revenue': 'Pendapatan',
    'expense': 'Beban',
  };
  static const _typeColors = {
    'asset': AppColors.info,
    'liability': AppColors.error,
    'equity': Color(0xFF6A1B9A),
    'revenue': AppColors.success,
    'expense': AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    if (coa.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: Text('Tidak ada data Chart of Accounts', style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    final grouped = <String, List<CoaEntity>>{};
    for (final c in coa) {
      grouped.putIfAbsent(c.accountType, () => []).add(c);
    }
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _typeLabels.keys.where((t) => grouped.containsKey(t)).map((type) {
          final items = grouped[type]!;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm, top: AppDimensions.md),
              child: Text(_typeLabels[type]!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _typeColors[type])),
            ),
            ...items.map((c) => Padding(
              padding: EdgeInsets.only(left: c.parentCode.isNotEmpty ? AppDimensions.lg : 0, bottom: 4),
              child: Row(children: [
                Text(c.code, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'), ),
                const SizedBox(width: AppDimensions.md),
                Expanded(child: Text(c.name, style: const TextStyle(fontSize: 13))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: (_typeColors[c.accountType] ?? AppColors.primary).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(_typeLabels[c.accountType] ?? c.accountType, style: TextStyle(fontSize: 10, color: _typeColors[c.accountType] ?? AppColors.primary)),
                ),
              ]),
            )),
            const Divider(color: AppColors.divider),
          ]);
        }).toList(),
      ),
    );
  }
}
