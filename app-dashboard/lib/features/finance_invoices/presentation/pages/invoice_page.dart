import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/invoice_detail_entity.dart';
import '../../domain/entities/invoice_stats_entity.dart';
import '../cubit/invoice_cubit.dart';
import '../cubit/invoice_state.dart';
import '../widgets/invoice_detail_modal.dart';

String _paymentMethodLabel(String method) {
  switch (method) {
    case 'upfront':
      return 'Upfront';
    case 'scheduled':
      return 'Cicilan';
    case 'monthly':
      return 'Bulanan';
    case 'batch_lump':
      return 'Lump Sum';
    case 'per_session':
      return 'Per Sesi';
    default:
      return method;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'overdue':
      return AppColors.error;
    case 'sent':
      return AppColors.info;
    case 'draft':
      return AppColors.textHint;
    case 'cancelled':
      return AppColors.textSecondary;
    default:
      return AppColors.textHint;
  }
}

Color _statusSurface(String status) {
  switch (status) {
    case 'paid':
      return AppColors.successSurface;
    case 'overdue':
      return AppColors.errorSurface;
    case 'sent':
      return AppColors.infoSurface;
    case 'draft':
      return AppColors.surfaceVariant;
    case 'cancelled':
      return AppColors.surfaceVariant;
    default:
      return AppColors.surfaceVariant;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'paid':
      return 'Lunas';
    case 'overdue':
      return 'Jatuh Tempo';
    case 'sent':
      return 'Terkirim';
    case 'draft':
      return 'Draft';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return status;
  }
}

class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<InvoiceCubit>()..loadAll(),
      child: const _InvoiceView(),
    );
  }
}

class _InvoiceView extends StatefulWidget {
  const _InvoiceView();

  @override
  State<_InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<_InvoiceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter controllers
  final _invoiceNumberCtrl = TextEditingController();
  final _studentNameCtrl = TextEditingController();
  String _filterStatus = '';
  String _filterPaymentMethod = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  // Pagination tracking per page tab index
  int _tab0Page = 0;
  int _tab1Page = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceNumberCtrl.dispose();
    _studentNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InvoiceCubit, InvoiceState>(
      listener: (context, state) {
        if (state is InvoiceActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is InvoiceError &&
            state is! InvoiceLoading &&
            state is! InvoiceLoaded) {
          // Reset page counters on reload
          setState(() {
            _tab0Page = 0;
            _tab1Page = 0;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      'Kelola faktur penjualan siswa',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Buat Invoice Manual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.md,
                        vertical: AppDimensions.sm),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => BlocProvider.value(
                      value: context.read<InvoiceCubit>(),
                      child: const CreateManualInvoiceDialog(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),

            // Stats
            BlocBuilder<InvoiceCubit, InvoiceState>(
              builder: (context, state) {
                if (state is InvoiceLoaded) {
                  return _StatsRow(stats: state.stats);
                }
                if (state is InvoiceActionSuccess) {
                  return _StatsRow(stats: state.previous.stats);
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: AppDimensions.md),

            // Filter bar (Tab 0 only)
            if (_tabController.index == 0)
              _FilterBar(
                invoiceNumberCtrl: _invoiceNumberCtrl,
                studentNameCtrl: _studentNameCtrl,
                filterStatus: _filterStatus,
                filterPaymentMethod: _filterPaymentMethod,
                fromDate: _fromDate,
                toDate: _toDate,
                onStatusChanged: (v) => setState(() => _filterStatus = v),
                onPaymentMethodChanged: (v) =>
                    setState(() => _filterPaymentMethod = v),
                onFromDateChanged: (d) => setState(() => _fromDate = d),
                onToDateChanged: (d) => setState(() => _toDate = d),
                onSearch: () {
                  setState(() => _tab0Page = 0);
                  context.read<InvoiceCubit>().applyFilter(
                        InvoiceFilterState(
                          invoiceNumber: _invoiceNumberCtrl.text.trim(),
                          studentName: _studentNameCtrl.text.trim(),
                          status: _filterStatus,
                          paymentMethod: _filterPaymentMethod,
                          fromDate: _fromDate?.toIso8601String(),
                          toDate: _toDate?.toIso8601String(),
                        ),
                      );
                },
                onReset: () {
                  setState(() {
                    _invoiceNumberCtrl.clear();
                    _studentNameCtrl.clear();
                    _filterStatus = '';
                    _filterPaymentMethod = '';
                    _fromDate = null;
                    _toDate = null;
                    _tab0Page = 0;
                  });
                  context
                      .read<InvoiceCubit>()
                      .applyFilter(const InvoiceFilterState());
                },
              ),

            const SizedBox(height: AppDimensions.sm),

            // TabBar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Semua Invoice'),
                  Tab(text: 'Jatuh Tempo'),
                  Tab(text: 'Riwayat Pembayaran'),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: BlocBuilder<InvoiceCubit, InvoiceState>(
                builder: (context, state) {
                  if (state is InvoiceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is InvoiceError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: AppColors.error),
                          const SizedBox(height: AppDimensions.md),
                          Text(state.message,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: AppDimensions.md),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<InvoiceCubit>().loadAll(),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }

                  InvoiceLoaded? loaded;
                  if (state is InvoiceLoaded) loaded = state;
                  if (state is InvoiceActionSuccess) loaded = state.previous;

                  if (loaded == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _AllInvoicesTab(
                        invoices: loaded.invoices,
                        currentPage: _tab0Page,
                        hasMore: loaded.hasMore,
                        onPageChanged: (p) => setState(() => _tab0Page = p),
                        onLoadMore: () =>
                            context.read<InvoiceCubit>().loadMore(),
                      ),
                      _OverdueTab(
                        invoices: loaded.invoices
                            .where((i) => i.status == 'overdue')
                            .toList()
                          ..sort((a, b) => a.dueDate.compareTo(b.dueDate)),
                        currentPage: _tab1Page,
                        onPageChanged: (p) => setState(() => _tab1Page = p),
                      ),
                      _PaymentHistoryTab(invoices: loaded.invoices),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Stats Row ----------

class _StatsRow extends StatelessWidget {
  final InvoiceStatsEntity stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Invoice',
            count: stats.totalCount,
            borderColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatCard(
            label: 'Lunas',
            count: stats.paidCount,
            amount: currencyFormat.format(stats.paidAmount),
            borderColor: AppColors.success,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatCard(
            label: 'Belum Lunas',
            count: stats.outstandingCount,
            amount: currencyFormat.format(stats.outstandingAmount),
            borderColor: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: _StatCard(
            label: 'Jatuh Tempo',
            count: stats.overdueCount,
            amount: currencyFormat.format(stats.overdueAmount),
            borderColor: AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final String? amount;
  final Color borderColor;

  const _StatCard({
    required this.label,
    required this.count,
    this.amount,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  count.toString(),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                if (amount != null)
                  Text(
                    amount!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Filter Bar ----------

class _FilterBar extends StatelessWidget {
  final TextEditingController invoiceNumberCtrl;
  final TextEditingController studentNameCtrl;
  final String filterStatus;
  final String filterPaymentMethod;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;
  final VoidCallback onSearch;
  final VoidCallback onReset;

  const _FilterBar({
    required this.invoiceNumberCtrl,
    required this.studentNameCtrl,
    required this.filterStatus,
    required this.filterPaymentMethod,
    required this.fromDate,
    required this.toDate,
    required this.onStatusChanged,
    required this.onPaymentMethodChanged,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.onSearch,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimensions.sm,
            runSpacing: AppDimensions.sm,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: invoiceNumberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Invoice',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.sm),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: TextField(
                  controller: studentNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Siswa',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.sm),
                  ),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: filterStatus,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.sm),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Semua')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'sent', child: Text('Terkirim')),
                    DropdownMenuItem(value: 'paid', child: Text('Lunas')),
                    DropdownMenuItem(
                        value: 'overdue', child: Text('Jatuh Tempo')),
                    DropdownMenuItem(
                        value: 'cancelled', child: Text('Dibatalkan')),
                  ],
                  onChanged: (v) => onStatusChanged(v ?? ''),
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: filterPaymentMethod,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Metode',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.sm),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Semua')),
                    DropdownMenuItem(
                        value: 'upfront', child: Text('Upfront')),
                    DropdownMenuItem(
                        value: 'scheduled', child: Text('Cicilan')),
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Bulanan')),
                    DropdownMenuItem(
                        value: 'batch_lump', child: Text('Lump Sum')),
                    DropdownMenuItem(
                        value: 'per_session', child: Text('Per Sesi')),
                  ],
                  onChanged: (v) => onPaymentMethodChanged(v ?? ''),
                ),
              ),
              _DateFilterChip(
                label: fromDate != null
                    ? 'Dari: ${dateFormat.format(fromDate!)}'
                    : 'Dari Tanggal',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: fromDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  onFromDateChanged(picked);
                },
                onClear: fromDate != null ? () => onFromDateChanged(null) : null,
              ),
              _DateFilterChip(
                label: toDate != null
                    ? 'Sampai: ${dateFormat.format(toDate!)}'
                    : 'Sampai Tanggal',
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: toDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  onToDateChanged(picked);
                },
                onClear: toDate != null ? () => onToDateChanged(null) : null,
              ),
              ElevatedButton(
                onPressed: onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm + 2),
                ),
                child: const Text('Cari'),
              ),
              OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.sm + 2),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateFilterChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateFilterChip({
    required this.label,
    required this.onTap,
    this.onClear,
  });

  @override
  State<_DateFilterChip> createState() => _DateFilterChipState();
}

class _DateFilterChipState extends State<_DateFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm, vertical: AppDimensions.sm),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              if (widget.onClear != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onClear,
                  child: const Icon(Icons.close,
                      size: 14, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Tab 1: All Invoices ----------

class _AllInvoicesTab extends StatelessWidget {
  final List<InvoiceDetailEntity> invoices;
  final int currentPage;
  final bool hasMore;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onLoadMore;

  const _AllInvoicesTab({
    required this.invoices,
    required this.currentPage,
    required this.hasMore,
    required this.onPageChanged,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.textHint),
            SizedBox(height: AppDimensions.md),
            Text('Tidak ada invoice',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    const pageSize = 20;
    final start = currentPage * pageSize;
    final end =
        (start + pageSize).clamp(0, invoices.length);
    final pageItems = invoices.sublist(start, end);
    final totalPages =
        ((invoices.length - 1) ~/ pageSize) + 1;

    return Column(
      children: [
        Expanded(child: _InvoiceTable(invoices: pageItems)),
        _PaginationRow(
          currentPage: currentPage,
          totalPages: totalPages,
          hasMore: hasMore,
          onPrev: currentPage > 0
              ? () => onPageChanged(currentPage - 1)
              : null,
          onNext: (currentPage + 1) < totalPages
              ? () => onPageChanged(currentPage + 1)
              : hasMore
                  ? () {
                      onLoadMore();
                      onPageChanged(currentPage + 1);
                    }
                  : null,
        ),
      ],
    );
  }
}

// ---------- Tab 2: Overdue ----------

class _OverdueTab extends StatelessWidget {
  final List<InvoiceDetailEntity> invoices;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _OverdueTab({
    required this.invoices,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: AppColors.success),
            SizedBox(height: AppDimensions.md),
            Text('Tidak ada invoice jatuh tempo',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    const pageSize = 20;
    final start = currentPage * pageSize;
    final end = (start + pageSize).clamp(0, invoices.length);
    final pageItems = invoices.sublist(start, end);
    final totalPages = ((invoices.length - 1) ~/ pageSize) + 1;

    return Column(
      children: [
        Expanded(child: _InvoiceTable(invoices: pageItems)),
        _PaginationRow(
          currentPage: currentPage,
          totalPages: totalPages,
          hasMore: false,
          onPrev: currentPage > 0
              ? () => onPageChanged(currentPage - 1)
              : null,
          onNext: (currentPage + 1) < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
  }
}

// ---------- Tab 3: Payment History ----------

class _PaymentHistoryTab extends StatelessWidget {
  final List<InvoiceDetailEntity> invoices;

  const _PaymentHistoryTab({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    // Flatten all payment history entries
    final entries = <Map<String, dynamic>>[];
    for (final inv in invoices) {
      for (final ph in inv.paymentHistory) {
        entries.add({
          'paidAt': ph.paidAt,
          'invoiceNumber': inv.invoiceNumber,
          'studentName': inv.studentName,
          'amount': ph.amount,
          'method': ph.method,
          'proofUrl': ph.proofUrl,
        });
      }
    }

    entries.sort((a, b) =>
        (b['paidAt'] as DateTime).compareTo(a['paidAt'] as DateTime));

    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: AppColors.textHint),
            SizedBox(height: AppDimensions.md),
            Text('Belum ada riwayat pembayaran',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header row
          Container(
            color: AppColors.surfaceVariant,
            child: const Row(
              children: [
                Expanded(
                    flex: 2,
                    child: _TableHeader('Tanggal Bayar')),
                Expanded(
                    flex: 2,
                    child: _TableHeader('No Invoice')),
                Expanded(
                    flex: 2,
                    child: _TableHeader('Siswa/Client')),
                Expanded(
                    flex: 2,
                    child: _TableHeader('Jumlah')),
                Expanded(
                    flex: 2,
                    child: _TableHeader('Metode Bayar')),
                Expanded(
                    flex: 1,
                    child: _TableHeader('Bukti')),
              ],
            ),
          ),
          const Divider(height: 1),
          ...entries.map(
            (e) => Column(
              children: [
                Container(
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: _TableCell(
                              dateFormat.format(e['paidAt'] as DateTime))),
                      Expanded(
                          flex: 2,
                          child: _TableCell(
                            e['invoiceNumber'] as String,
                            monospace: true,
                          )),
                      Expanded(
                          flex: 2,
                          child: _TableCell(e['studentName'] as String)),
                      Expanded(
                          flex: 2,
                          child: _TableCell(
                              currencyFormat.format(e['amount'] as double))),
                      Expanded(
                          flex: 2,
                          child: _TableCell(e['method'] as String)),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimensions.sm),
                          child: e['proofUrl'] != null
                              ? TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    'Lihat Bukti',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.info),
                                  ),
                                )
                              : const Text(
                                  '—',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm, vertical: AppDimensions.sm),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool monospace;
  const _TableCell(this.text, {this.monospace = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.sm),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          fontFamily: monospace ? 'monospace' : null,
        ),
      ),
    );
  }
}

// ---------- Invoice Table (shared) ----------

class _InvoiceTable extends StatelessWidget {
  final List<InvoiceDetailEntity> invoices;

  const _InvoiceTable({required this.invoices});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            color: AppColors.surfaceVariant,
            child: const Row(
              children: [
                SizedBox(width: AppDimensions.sm),
                Expanded(flex: 2, child: _TableHeader('No Invoice')),
                Expanded(flex: 2, child: _TableHeader('Siswa/Client')),
                Expanded(flex: 2, child: _TableHeader('Batch')),
                Expanded(flex: 2, child: _TableHeader('Jumlah')),
                Expanded(flex: 1, child: _TableHeader('Metode')),
                Expanded(flex: 2, child: _TableHeader('Jatuh Tempo')),
                Expanded(flex: 1, child: _TableHeader('Status')),
                SizedBox(width: 80, child: _TableHeader('Aksi')),
              ],
            ),
          ),
          const Divider(height: 1),
          ...invoices.map(
            (inv) => _InvoiceRow(
              invoice: inv,
              currencyFormat: currencyFormat,
              dateFormat: dateFormat,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatefulWidget {
  final InvoiceDetailEntity invoice;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  const _InvoiceRow({
    required this.invoice,
    required this.currencyFormat,
    required this.dateFormat,
  });

  @override
  State<_InvoiceRow> createState() => _InvoiceRowState();
}

class _InvoiceRowState extends State<_InvoiceRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    final isOverdue = inv.dueDate.isBefore(DateTime.now()) &&
        inv.status != 'paid' &&
        inv.status != 'cancelled';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? AppColors.primarySurface : AppColors.surface,
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    child: Text(
                      inv.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _TableCell(inv.studentName),
                ),
                Expanded(
                  flex: 2,
                  child: _TableCell(inv.batchCode),
                ),
                Expanded(
                  flex: 2,
                  child: _TableCell(widget.currencyFormat.format(inv.amount)),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.infoSurface,
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusCircle),
                      ),
                      child: Text(
                        _paymentMethodLabel(inv.paymentMethod),
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.info,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    child: Text(
                      widget.dateFormat.format(inv.dueDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: isOverdue
                            ? AppColors.error
                            : AppColors.textPrimary,
                        fontWeight: isOverdue
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusSurface(inv.status),
                        borderRadius: BorderRadius.circular(
                            AppDimensions.radiusCircle),
                      ),
                      child: Text(
                        _statusLabel(inv.status),
                        style: TextStyle(
                          fontSize: 10,
                          color: _statusColor(inv.status),
                          fontWeight: FontWeight.w600,
                          decoration: inv.status == 'cancelled'
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined,
                            size: AppDimensions.iconMd,
                            color: AppColors.textSecondary),
                        tooltip: 'Detail',
                        onPressed: () =>
                            showInvoiceDetailModal(context, inv),
                      ),
                      IconButton(
                        icon: const Icon(Icons.email_outlined,
                            size: AppDimensions.iconMd,
                            color: AppColors.textSecondary),
                        tooltip: 'Kirim Ulang',
                        onPressed: inv.status != 'cancelled'
                            ? () =>
                                context.read<InvoiceCubit>().resendInvoice(inv.id)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 1, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}

// ---------- Pagination Row ----------

class _PaginationRow extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationRow({
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.sm, horizontal: AppDimensions.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.chevron_left, size: 16),
            label: const Text('< Prev'),
            onPressed: onPrev,
            style: OutlinedButton.styleFrom(
              foregroundColor: onPrev != null
                  ? AppColors.primary
                  : AppColors.textHint,
              side: BorderSide(
                  color: onPrev != null
                      ? AppColors.primary
                      : AppColors.border),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.xs),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Text(
            'Halaman ${currentPage + 1}${totalPages > 1 ? ' dari $totalPages' : ''}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppDimensions.md),
          OutlinedButton.icon(
            icon: const Icon(Icons.chevron_right, size: 16),
            label: const Text('Next >'),
            onPressed: onNext,
            style: OutlinedButton.styleFrom(
              foregroundColor: onNext != null
                  ? AppColors.primary
                  : AppColors.textHint,
              side: BorderSide(
                  color: onNext != null
                      ? AppColors.primary
                      : AppColors.border),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.xs),
            ),
          ),
        ],
      ),
    );
  }
}
