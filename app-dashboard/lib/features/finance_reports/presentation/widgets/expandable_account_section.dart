import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/balance_sheet_entity.dart';

final _currencyFmt =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class ExpandableAccountSection extends StatefulWidget {
  final String sectionName;
  final double total;
  final List<BalanceSheetAccountEntity> accounts;
  final Color? headerColor;

  const ExpandableAccountSection({
    super.key,
    required this.sectionName,
    required this.total,
    required this.accounts,
    this.headerColor,
  });

  @override
  State<ExpandableAccountSection> createState() =>
      _ExpandableAccountSectionState();
}

class _ExpandableAccountSectionState extends State<ExpandableAccountSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          _SectionHeader(
            name: widget.sectionName,
            total: widget.total,
            expanded: _expanded,
            headerColor: widget.headerColor,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            ...widget.accounts.map((a) => _AccountRow(account: a)),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatefulWidget {
  final String name;
  final double total;
  final bool expanded;
  final Color? headerColor;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.name,
    required this.total,
    required this.expanded,
    required this.onTap,
    this.headerColor,
  });

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.headerColor ?? AppColors.primarySurface;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md, vertical: AppDimensions.sm + 2),
          decoration: BoxDecoration(
            color: _hovered ? bg.withValues(alpha: 0.7) : bg,
            borderRadius: widget.expanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusMd),
                    topRight: Radius.circular(AppDimensions.radiusMd),
                  )
                : BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                widget.expanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: AppDimensions.iconMd,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.xs),
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                _currencyFmt.format(widget.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final BalanceSheetAccountEntity account;
  final int depth;

  const _AccountRow({required this.account, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final isNegativeAmount = account.isNegative || account.amount < 0;
    final displayAmount = account.amount.abs();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            left: AppDimensions.md + (depth * 16.0),
            right: AppDimensions.md,
            top: AppDimensions.xs + 2,
            bottom: AppDimensions.xs + 2,
          ),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: Row(
            children: [
              Text(
                account.code,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  account.name,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                ),
              ),
              Text(
                isNegativeAmount
                    ? '(${_currencyFmt.format(displayAmount)})'
                    : _currencyFmt.format(displayAmount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isNegativeAmount ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...account.children
            .map((child) => _AccountRow(account: child, depth: depth + 1)),
      ],
    );
  }
}
