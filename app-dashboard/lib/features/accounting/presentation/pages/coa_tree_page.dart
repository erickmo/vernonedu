import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/coa_tree_node_entity.dart';
import '../cubit/coa_tree_cubit.dart';

const String _kTitle = 'Bagan Akun (Pohon)';
const String _kEmpty = 'Belum ada akun';
const String _kBalanceUnknown = '—';
const double _kIndentPerDepth = 16.0;

final NumberFormat _kCurrency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class CoaTreePage extends StatelessWidget {
  const CoaTreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CoaTreeCubit>()..load(),
      child: const _CoaTreeView(),
    );
  }
}

class _CoaTreeView extends StatelessWidget {
  const _CoaTreeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(_kTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: BlocBuilder<CoaTreeCubit, CoaTreeState>(
          builder: (context, state) {
            if (state is CoaTreeLoading || state is CoaTreeInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CoaTreeError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }
            if (state is CoaTreeLoaded) {
              if (state.roots.isEmpty) return const _EmptyView();
              return _CoaTreeList(roots: state.roots);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined,
              size: 48, color: AppColors.textHint),
          SizedBox(height: AppDimensions.sm),
          Text(
            _kEmpty,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CoaTreeList extends StatelessWidget {
  final List<CoaTreeNodeEntity> roots;
  const _CoaTreeList({required this.roots});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimensions.cardElevation.toDouble(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListView.builder(
        itemCount: roots.length,
        itemBuilder: (_, i) => CoaTreeNodeTile(node: roots[i], depth: 0),
      ),
    );
  }
}

/// Recursive tile for a single COA node and its children.
class CoaTreeNodeTile extends StatelessWidget {
  final CoaTreeNodeEntity node;
  final int depth;

  const CoaTreeNodeTile({
    super.key,
    required this.node,
    required this.depth,
  });

  bool get _hasChildren => node.children.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final indent = EdgeInsets.only(left: depth * _kIndentPerDepth);
    if (!_hasChildren) {
      return Padding(
        padding: indent,
        child: ListTile(
          dense: true,
          title: _NodeRow(node: node),
        ),
      );
    }
    return Padding(
      padding: indent,
      child: ExpansionTile(
        title: _NodeRow(node: node),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: depth == 0,
        children: node.children
            .map((c) => CoaTreeNodeTile(node: c, depth: depth + 1))
            .toList(),
      ),
    );
  }
}

class _NodeRow extends StatelessWidget {
  final CoaTreeNodeEntity node;
  const _NodeRow({required this.node});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          node.code,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Text(
            node.name,
            style: const TextStyle(color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        _BalanceText(balance: node.balance),
      ],
    );
  }
}

class _BalanceText extends StatelessWidget {
  final num? balance;
  const _BalanceText({required this.balance});

  @override
  Widget build(BuildContext context) {
    if (balance == null) {
      return const Text(
        _kBalanceUnknown,
        style: TextStyle(color: AppColors.textHint),
      );
    }
    final value = balance!;
    final isNegative = value < 0;
    return Text(
      _kCurrency.format(value),
      style: TextStyle(
        color: isNegative ? AppColors.error : AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
