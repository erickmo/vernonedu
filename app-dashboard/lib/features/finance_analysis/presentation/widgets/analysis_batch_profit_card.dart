import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/finance_analysis_entity.dart';
import '_card_shell.dart';

class AnalysisBatchProfitCard extends StatefulWidget {
  final BatchProfitEntity batchProfit;

  const AnalysisBatchProfitCard({super.key, required this.batchProfit});

  @override
  State<AnalysisBatchProfitCard> createState() =>
      _AnalysisBatchProfitCardState();
}

class _AnalysisBatchProfitCardState extends State<AnalysisBatchProfitCard> {
  int _sortColumnIndex = 3; // profit
  bool _sortAscending = false;

  List<BatchProfitItem> _sortedItems() {
    final items = List<BatchProfitItem>.from(widget.batchProfit.items);
    int cmp(num a, num b) => a.compareTo(b);
    items.sort((a, b) {
      final r = switch (_sortColumnIndex) {
        1 => cmp(a.revenue, b.revenue),
        2 => cmp(a.expense, b.expense),
        3 => cmp(a.profit, b.profit),
        _ => a.batchCode.compareTo(b.batchCode),
      };
      return _sortAscending ? r : -r;
    });
    return items;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _sortedItems();
    return AnalysisCardShell(
      title: 'Profitabilitas Batch',
      icon: Icons.business_center_outlined,
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.md),
              child: Text(
                'Belum ada data profitabilitas batch',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columnSpacing: AppDimensions.lg,
                headingRowHeight: 40,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 48,
                columns: [
                  DataColumn(
                    label: const Text('Batch'),
                    onSort: _onSort,
                  ),
                  DataColumn(
                    label: const Text('Pendapatan'),
                    numeric: true,
                    onSort: _onSort,
                  ),
                  DataColumn(
                    label: const Text('Biaya'),
                    numeric: true,
                    onSort: _onSort,
                  ),
                  DataColumn(
                    label: const Text('Laba'),
                    numeric: true,
                    onSort: _onSort,
                  ),
                ],
                rows: items
                    .map((item) => DataRow(
                          cells: [
                            DataCell(Text(
                              '${item.batchCode}\n${item.courseName}',
                              style: const TextStyle(fontSize: 12),
                            )),
                            DataCell(Text(kIdrFormat.format(item.revenue))),
                            DataCell(Text(kIdrFormat.format(item.expense))),
                            DataCell(Text(
                              kIdrFormat.format(item.profit),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: item.profit < 0
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            )),
                          ],
                        ))
                    .toList(),
              ),
            ),
    );
  }
}
