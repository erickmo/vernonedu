import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/certificate_template_entity.dart';
import '../cubit/certificate_template_cubit.dart';
import '../cubit/template_editor_cubit.dart';
import '../widgets/a4_certificate_preview.dart';
import '../widgets/template_basic_form.dart';
import '../widgets/template_layout_form.dart';
import '../widgets/template_signature_form.dart';

const double _kDesktopBreakpoint = 900;
const int _kFormFlex = 5;
const int _kPreviewFlex = 7;

/// Editor for a certificate template. When [templateId] is null, creates a
/// new template; otherwise loads the existing template.
class CertificateTemplateEditorPage extends StatelessWidget {
  final String? templateId;
  const CertificateTemplateEditorPage({super.key, this.templateId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<CertificateTemplateCubit>()..load(),
        ),
        BlocProvider(
          create: (ctx) => TemplateEditorCubit(
            templateCubit: ctx.read<CertificateTemplateCubit>(),
          ),
        ),
      ],
      child: _EditorView(templateId: templateId),
    );
  }
}

class _EditorView extends StatefulWidget {
  final String? templateId;
  const _EditorView({required this.templateId});

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  bool _initialized = false;

  void _hydrateIfNeeded(List<CertificateTemplateEntity> templates) {
    if (_initialized) return;
    if (widget.templateId == null) {
      _initialized = true;
      return;
    }
    final match = templates.where((t) => t.id == widget.templateId);
    if (match.isEmpty) return;
    _initialized = true;
    context.read<TemplateEditorCubit>().loadExisting(match.first);
  }

  Future<bool> _confirmDiscard() async {
    final dirty = context.read<TemplateEditorCubit>().state.isDirty;
    if (!dirty) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Buang Perubahan?'),
        content:
            const Text('Perubahan yang belum disimpan akan hilang. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Buang')),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _save() async {
    final ok = await context.read<TemplateEditorCubit>().save();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template tersimpan')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/certificate-templates');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan template')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CertificateTemplateCubit, CertificateTemplateState>(
      listener: (_, state) {
        if (state is CertificateTemplateLoaded) {
          _hydrateIfNeeded(state.templates);
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          if (await _confirmDiscard() && context.mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/certificate-templates');
            }
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(),
          body: LayoutBuilder(
            builder: (ctx, c) {
              final isDesktop = c.maxWidth >= _kDesktopBreakpoint;
              return isDesktop ? _buildDesktop() : _buildMobile();
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.templateId == null ? 'Template Baru' : 'Edit Template',
      ),
      actions: [
        BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
          builder: (ctx, state) => Padding(
            padding: const EdgeInsets.only(right: AppDimensions.md),
            child: Row(
              children: [
                TextButton(
                  onPressed: state.isSaving
                      ? null
                      : () async {
                          if (await _confirmDiscard() && mounted) {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/certificate-templates');
                            }
                          }
                        },
                  child: const Text('Batal'),
                ),
                const SizedBox(width: AppDimensions.sm),
                FilledButton.icon(
                  onPressed: !state.isDirty || state.isSaving ? null : _save,
                  icon: state.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        Expanded(flex: _kFormFlex, child: _buildForm()),
        Expanded(flex: _kPreviewFlex, child: _buildPreview()),
      ],
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _buildPreview(maxHeight: 500),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          TemplateBasicForm(),
          SizedBox(height: AppDimensions.lg),
          TemplateLayoutForm(),
          SizedBox(height: AppDimensions.lg),
          TemplateSignatureForm(),
        ],
      ),
    );
  }

  Widget _buildPreview({double? maxHeight}) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppDimensions.lg),
      constraints:
          maxHeight != null ? BoxConstraints(maxHeight: maxHeight) : null,
      child: Center(
        child: BlocBuilder<TemplateEditorCubit, TemplateEditorState>(
          builder: (ctx, state) =>
              A4CertificatePreview(config: state.draft),
        ),
      ),
    );
  }
}
