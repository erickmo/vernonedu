import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/report_filter_entity.dart';

class ReportFilterBar extends StatefulWidget {
  final ReportFilterEntity initialFilter;
  final void Function(ReportFilterEntity) onFilterChanged;
  final bool showAccountFilter;
  final String? accountFilterValue;
  final void Function(String)? onAccountChanged;

  const ReportFilterBar({
    super.key,
    required this.initialFilter,
    required this.onFilterChanged,
    this.showAccountFilter = false,
    this.accountFilterValue,
    this.onAccountChanged,
  });

  @override
  State<ReportFilterBar> createState() => _ReportFilterBarState();
}

class _ReportFilterBarState extends State<ReportFilterBar> {
  late ReportFilterEntity _filter;
  final _accountController = TextEditingController();

  static const _periodOptions = [
    ('monthly', 'Bulanan'),
    ('quarterly', 'Kuartalan'),
    ('yearly', 'Tahunan'),
    ('custom', 'Custom'),
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    if (widget.accountFilterValue != null) {
      _accountController.text = widget.accountFilterValue!;
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _filter.fromDate != null && _filter.toDate != null
          ? DateTimeRange(start: _filter.fromDate!, end: _filter.toDate!)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _filter = _filter.copyWith(
          fromDate: picked.start,
          toDate: picked.end,
        );
      });
      widget.onFilterChanged(_filter);
    }
  }

  void _showExportSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ekspor akan segera tersedia'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'id');
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppDimensions.md,
        runSpacing: AppDimensions.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Period dropdown
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              value: _filter.period,
              decoration: const InputDecoration(
                labelText: 'Periode',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
              items: _periodOptions
                  .map((o) => DropdownMenuItem(
                        value: o.$1,
                        child: Text(o.$2, style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _filter = _filter.copyWith(period: val);
                });
                widget.onFilterChanged(_filter);
              },
            ),
          ),

          // Date range picker (shown if period == custom)
          if (_filter.period == 'custom')
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range, size: AppDimensions.iconMd),
              label: Text(
                _filter.fromDate != null && _filter.toDate != null
                    ? '${fmt.format(_filter.fromDate!)} – ${fmt.format(_filter.toDate!)}'
                    : 'Pilih Rentang Tanggal',
                style: const TextStyle(fontSize: 13),
              ),
              onPressed: _pickDateRange,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

          // Account filter (optional)
          if (widget.showAccountFilter)
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Kode / Nama Akun',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search, size: AppDimensions.iconMd),
                ),
                onChanged: widget.onAccountChanged,
                style: const TextStyle(fontSize: 13),
              ),
            ),

          const Spacer(),

          // Export PDF
          _ExportButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Ekspor PDF',
            onTap: () => _showExportSnackBar(context),
          ),
          // Export Excel
          _ExportButton(
            icon: Icons.table_chart_outlined,
            label: 'Ekspor Excel',
            onTap: () => _showExportSnackBar(context),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primarySurface : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: _hovered ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  size: AppDimensions.iconMd,
                  color: _hovered ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: AppDimensions.xs),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
