import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../cubit/template_editor_cubit.dart';

const List<String> _kFontFamilies = [
  'Roboto',
  'Lora',
  'Playfair Display',
  'Poppins',
  'Inter',
];

const List<String> _kQrPositions = [
  'top-left',
  'top-right',
  'bottom-left',
  'bottom-right',
  'none',
];

/// Typography + position sliders + QR + background URL.
class TemplateLayoutForm extends StatelessWidget {
  const TemplateLayoutForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      builder: (ctx, state) {
        final cubit = ctx.read<TemplateEditorCubit>();
        final d = state.draft;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, 'Tipografi'),
            DropdownButtonFormField<String>(
              value: _kFontFamilies.contains(d.fontFamily)
                  ? d.fontFamily
                  : _kFontFamilies.first,
              decoration: const InputDecoration(labelText: 'Font Family'),
              items: _kFontFamilies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) {
                if (v != null) cubit.setFontFamily(v);
              },
            ),
            const SizedBox(height: AppDimensions.md),
            TextFormField(
              key: ValueKey('font-size-${d.titleSize}'),
              initialValue: d.titleSize.toStringAsFixed(0),
              decoration: const InputDecoration(labelText: 'Ukuran Judul (pt)'),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null && parsed > 0) cubit.setFontSize(parsed);
              },
            ),
            const SizedBox(height: AppDimensions.lg),
            _header(context, 'Posisi Judul'),
            _PositionSlider(
              label: 'X',
              value: d.titleX,
              onChanged: cubit.setTitleX,
            ),
            _PositionSlider(
              label: 'Y',
              value: d.titleY,
              onChanged: cubit.setTitleY,
            ),
            const SizedBox(height: AppDimensions.lg),
            _header(context, 'Posisi Isi'),
            _PositionSlider(
              label: 'X',
              value: d.bodyX,
              onChanged: cubit.setBodyX,
            ),
            _PositionSlider(
              label: 'Y',
              value: d.bodyY,
              onChanged: cubit.setBodyY,
            ),
            const SizedBox(height: AppDimensions.lg),
            _header(context, 'QR Code'),
            DropdownButtonFormField<String>(
              value: _kQrPositions.contains(d.qrPosition)
                  ? d.qrPosition
                  : _kQrPositions.first,
              decoration: const InputDecoration(labelText: 'Posisi QR'),
              items: _kQrPositions
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) {
                if (v != null) cubit.setQrPosition(v);
              },
            ),
            const SizedBox(height: AppDimensions.lg),
            _header(context, 'Latar Belakang'),
            TextFormField(
              key: ValueKey('bg-${d.backgroundUrl}'),
              initialValue: d.backgroundUrl ?? '',
              decoration: const InputDecoration(
                labelText: 'URL Gambar Latar (opsional)',
                hintText: 'https://...',
              ),
              onChanged: cubit.setBackgroundUrl,
            ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.sm),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );
}

class _PositionSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _PositionSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            value.toStringAsFixed(2),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
