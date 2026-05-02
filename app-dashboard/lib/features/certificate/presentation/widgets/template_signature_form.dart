import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../cubit/template_editor_cubit.dart';

/// Manages the list of signature blocks (name, role, x, y).
class TemplateSignatureForm extends StatelessWidget {
  const TemplateSignatureForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      buildWhen: (a, b) =>
          a.draft.signatureBlocks != b.draft.signatureBlocks,
      builder: (ctx, state) {
        final cubit = ctx.read<TemplateEditorCubit>();
        final blocks = state.draft.signatureBlocks;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Tanda Tangan',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: cubit.addSignatureBlock,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            if (blocks.isEmpty)
              const Text('Belum ada tanda tangan',
                  style: TextStyle(color: Colors.grey))
            else
              ...List.generate(blocks.length, (i) {
                return _SignatureRow(
                  key: ValueKey('sig-$i'),
                  index: i,
                  block: blocks[i],
                  onChanged: (b) => cubit.updateSignatureBlock(i, b),
                  onRemove: () => cubit.removeSignatureBlock(i),
                );
              }),
          ],
        );
      },
    );
  }
}

class _SignatureRow extends StatelessWidget {
  final int index;
  final SignatureBlockEntity block;
  final ValueChanged<SignatureBlockEntity> onChanged;
  final VoidCallback onRemove;

  const _SignatureRow({
    required this.index,
    required this.block,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('sig-$index-name'),
                    initialValue: block.name,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    onChanged: (v) => onChanged(block.copyWith(name: v)),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('sig-$index-role'),
                    initialValue: block.role,
                    decoration: const InputDecoration(labelText: 'Jabatan'),
                    onChanged: (v) => onChanged(block.copyWith(role: v)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                  tooltip: 'Hapus',
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _SmallSlider(
                    label: 'X',
                    value: block.x,
                    onChanged: (v) => onChanged(block.copyWith(x: v)),
                  ),
                ),
                Expanded(
                  child: _SmallSlider(
                    label: 'Y',
                    value: block.y,
                    onChanged: (v) => onChanged(block.copyWith(y: v)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _SmallSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 20, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 40, child: Text(value.toStringAsFixed(2))),
      ],
    );
  }
}
