import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/di/injection.dart';
import '../../domain/entities/coa_entity.dart';
import '../cubit/accounting_cubit.dart';

class ChartOfAccountsPage extends StatelessWidget {
  const ChartOfAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountingCubit>()..loadAll(),
      child: const _CoaView(),
    );
  }
}

class _CoaView extends StatelessWidget {
  const _CoaView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppDimensions.md),
          Expanded(
            child: BlocBuilder<AccountingCubit, AccountingState>(
              builder: (context, state) {
                if (state is AccountingLoading || state is AccountingInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AccountingError) {
                  return Center(
                    child: Text(state.message,
                        style: const TextStyle(color: AppColors.error)),
                  );
                }
                if (state is AccountingLoaded) {
                  return _CoaTree(accounts: state.coa);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Akun (Chart of Accounts)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              'Struktur akun keuangan perusahaan',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showAddAccountDialog(context),
          icon: const Icon(Icons.add, size: AppDimensions.iconMd),
          label: const Text('+ Tambah Akun'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddAccountDialog(),
    );
  }
}

class _CoaTree extends StatelessWidget {
  final List<CoaEntity> accounts;

  const _CoaTree({required this.accounts});

  /// Groups accounts by root category (first digit of code).
  Map<String, List<CoaEntity>> _buildGroups() {
    final Map<String, List<CoaEntity>> groups = {};
    for (final acc in accounts) {
      final groupKey = acc.code.isNotEmpty ? acc.code[0] : '0';
      groups.putIfAbsent(groupKey, () => []).add(acc);
    }
    return groups;
  }

  static const Map<String, String> _groupLabels = {
    '1': 'Aset',
    '2': 'Kewajiban',
    '3': 'Ekuitas',
    '4': 'Pendapatan',
    '5': 'Beban',
  };

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_tree_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.sm),
            const Text(
              'Tidak ada akun',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final groups = _buildGroups();
    final sortedKeys = groups.keys.toList()..sort();

    return Card(
      elevation: AppDimensions.cardElevation.toDouble(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildTableHeader(context),
          Expanded(
            child: ListView.builder(
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final key = sortedKeys[index];
                final label = _groupLabels[key] ?? 'Akun $key';
                final items = groups[key]!..sort((a, b) => a.code.compareTo(b.code));

                // Separate roots (parentCode empty) from children
                final roots = items.where((a) => a.parentCode.isEmpty).toList();
                final children = items.where((a) => a.parentCode.isNotEmpty).toList();

                return _AccountGroup(
                  code: '${key}000',
                  label: label,
                  roots: roots,
                  allChildren: children,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md, vertical: AppDimensions.sm),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusMd),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            flex: 2,
            child: Text('Kode',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )),
          ),
          Expanded(
            flex: 4,
            child: Text('Nama Akun',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )),
          ),
          Expanded(
            flex: 2,
            child: Text('Tipe',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )),
          ),
          SizedBox(
            width: 72,
            child: Text('Status',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )),
          ),
        ],
      ),
    );
  }
}

class _AccountGroup extends StatefulWidget {
  final String code;
  final String label;
  final List<CoaEntity> roots;
  final List<CoaEntity> allChildren;

  const _AccountGroup({
    required this.code,
    required this.label,
    required this.roots,
    required this.allChildren,
  });

  @override
  State<_AccountGroup> createState() => _AccountGroupState();
}

class _AccountGroupState extends State<_AccountGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Group header row
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            color: AppColors.surfaceVariant,
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right,
                    size: AppDimensions.iconMd,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.code,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox.shrink()),
                const SizedBox(width: 72),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          // Root accounts (parent of children)
          ...widget.roots.map((root) => _AccountNode(
                account: root,
                children: widget.allChildren
                    .where((c) => c.parentCode == root.code)
                    .toList(),
                depth: 1,
              )),
          // Children without matching roots (direct under group)
          ...widget.allChildren
              .where((c) =>
                  !widget.roots.any((r) => r.code == c.parentCode))
              .map((c) => _AccountRow(account: c, depth: 1)),
        ],
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

class _AccountNode extends StatefulWidget {
  final CoaEntity account;
  final List<CoaEntity> children;
  final int depth;

  const _AccountNode({
    required this.account,
    required this.children,
    required this.depth,
  });

  @override
  State<_AccountNode> createState() => _AccountNodeState();
}

class _AccountNodeState extends State<_AccountNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.children.isNotEmpty;
    return Column(
      children: [
        InkWell(
          onTap: hasChildren
              ? () => setState(() => _expanded = !_expanded)
              : null,
          child: _AccountRowContent(
            account: widget.account,
            depth: widget.depth,
            hasChildren: hasChildren,
            expanded: _expanded,
          ),
        ),
        if (hasChildren && _expanded)
          ...widget.children.map(
            (c) => _AccountRow(account: c, depth: widget.depth + 1),
          ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  final CoaEntity account;
  final int depth;

  const _AccountRow({required this.account, required this.depth});

  @override
  Widget build(BuildContext context) {
    return _AccountRowContent(
      account: account,
      depth: depth,
      hasChildren: false,
      expanded: false,
    );
  }
}

class _AccountRowContent extends StatelessWidget {
  final CoaEntity account;
  final int depth;
  final bool hasChildren;
  final bool expanded;

  const _AccountRowContent({
    required this.account,
    required this.depth,
    required this.hasChildren,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final indent = depth * 20.0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 40 + indent),
          if (hasChildren)
            Icon(
              expanded ? Icons.expand_more : Icons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            )
          else
            const SizedBox(width: 16),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Text(
              account.code,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              account.name,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: _TypeChip(type: account.accountType),
          ),
          SizedBox(
            width: 72,
            child: Center(
              child: _ActiveIndicator(isActive: account.isActive),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  Color get _color => switch (type) {
        'asset' => AppColors.info,
        'liability' => AppColors.warning,
        'equity' => AppColors.secondary,
        'revenue' => AppColors.success,
        'expense' => AppColors.error,
        _ => AppColors.textSecondary,
      };

  Color get _bg => switch (type) {
        'asset' => AppColors.infoSurface,
        'liability' => AppColors.warningSurface,
        'equity' => AppColors.primarySurface,
        'revenue' => AppColors.successSurface,
        'expense' => AppColors.errorSurface,
        _ => AppColors.surfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      'asset' => 'Aset',
      'liability' => 'Kewajiban',
      'equity' => 'Ekuitas',
      'revenue' => 'Pendapatan',
      'expense' => 'Beban',
      _ => type,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: _color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActiveIndicator extends StatelessWidget {
  final bool isActive;
  const _ActiveIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        isActive ? 'Aktif' : 'Nonaktif',
        style: TextStyle(
          fontSize: 11,
          color: isActive ? AppColors.success : AppColors.textHint,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog();

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _type = 'asset';

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Akun Baru'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Kode Akun',
                hintText: 'misal: 1101',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Akun',
                hintText: 'misal: Kas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Tipe Akun',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'asset', child: Text('Aset')),
                DropdownMenuItem(value: 'liability', child: Text('Kewajiban')),
                DropdownMenuItem(value: 'equity', child: Text('Ekuitas')),
                DropdownMenuItem(value: 'revenue', child: Text('Pendapatan')),
                DropdownMenuItem(value: 'expense', child: Text('Beban')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: wire to create COA command
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
