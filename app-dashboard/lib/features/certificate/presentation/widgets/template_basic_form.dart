import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../cubit/template_editor_cubit.dart';

const _kTypePeserta = 'participant';
const _kTypeKompetensi = 'competency';

/// Basic identity + content section: name, type, title, body text.
class TemplateBasicForm extends StatelessWidget {
  const TemplateBasicForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
      buildWhen: (a, b) =>
          a.draft.name != b.draft.name ||
          a.draft.type != b.draft.type ||
          a.draft.title != b.draft.title ||
          a.draft.bodyText != b.draft.bodyText,
      builder: (ctx, state) {
        final cubit = ctx.read<TemplateEditorCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader('Identitas'),
            TextFormField(
              key: const ValueKey('field-name'),
              initialValue: state.draft.name,
              decoration: const InputDecoration(labelText: 'Nama Template'),
              onChanged: cubit.setName,
            ),
            const SizedBox(height: AppDimensions.md),
            DropdownButtonFormField<String>(
              key: const ValueKey('field-type'),
              value: state.draft.type,
              decoration: const InputDecoration(labelText: 'Tipe'),
              items: const [
                DropdownMenuItem(value: _kTypePeserta, child: Text('Peserta')),
                DropdownMenuItem(
                    value: _kTypeKompetensi, child: Text('Kompetensi')),
              ],
              onChanged: (v) {
                if (v != null) cubit.setType(v);
              },
            ),
            const SizedBox(height: AppDimensions.lg),
            const _SectionHeader('Konten'),
            TextFormField(
              key: const ValueKey('field-title'),
              initialValue: state.draft.title,
              decoration: const InputDecoration(labelText: 'Judul'),
              onChanged: cubit.setTitle,
            ),
            const SizedBox(height: AppDimensions.md),
            TextFormField(
              key: const ValueKey('field-body'),
              initialValue: state.draft.bodyText,
              decoration: const InputDecoration(
                labelText: 'Isi',
                hintText: 'Gunakan {{nama_siswa}} dan {{nama_kursus}}',
              ),
              minLines: 3,
              maxLines: 6,
              onChanged: cubit.setBodyText,
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.sm),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}
