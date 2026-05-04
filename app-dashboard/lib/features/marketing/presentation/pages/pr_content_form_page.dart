import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/pr_schedule_entity.dart';
import '../cubit/marketing_cubit.dart';

class PrContentFormPage extends StatelessWidget {
  final PrScheduleEntity? prSchedule;

  const PrContentFormPage({super.key, this.prSchedule});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => context.read<MarketingCubit>(),
      child: _PrContentFormView(prSchedule: prSchedule),
    );
  }
}

class _PrContentFormView extends StatefulWidget {
  final PrScheduleEntity? prSchedule;
  const _PrContentFormView({this.prSchedule});

  @override
  State<_PrContentFormView> createState() => _PrContentFormViewState();
}

class _PrContentFormViewState extends State<_PrContentFormView> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _mediaVenueCtrl = TextEditingController();
  final _picNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _type = 'press_release';
  String _status = 'draft';
  DateTime? _scheduledAt;

  bool _isSubmitting = false;
  bool _initialized = false;

  bool get _isEdit => widget.prSchedule != null;

  static const _typeOptions = {
    'press_release': 'Press Release',
    'event': 'Event',
    'sponsorship': 'Sponsorship',
    'interview': 'Interview',
    'other': 'Lainnya',
  };

  static const _statusOptions = {
    'draft': 'Draft',
    'published': 'Published',
  };

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _prefillFromEntity();
    }
  }

  void _prefillFromEntity() {
    if (_initialized) return;
    _initialized = true;

    final pr = widget.prSchedule!;
    _titleCtrl.text = pr.title;
    _mediaVenueCtrl.text = pr.mediaVenue;
    _picNameCtrl.text = pr.picName;
    _notesCtrl.text = pr.notes;
    _type = pr.type;
    _status = pr.status;
    _scheduledAt = pr.scheduledAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _mediaVenueCtrl.dispose();
    _picNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledAt = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'title': _titleCtrl.text.trim(),
      'type': _type,
      'mediaVenue': _mediaVenueCtrl.text.trim(),
      'picName': _picNameCtrl.text.trim(),
      if (_isEdit) 'status': _status,
      'notes': _notesCtrl.text.trim(),
      if (_scheduledAt != null)
        'scheduledAt':
            '${_scheduledAt!.year.toString().padLeft(4, '0')}-'
            '${_scheduledAt!.month.toString().padLeft(2, '0')}-'
            '${_scheduledAt!.day.toString().padLeft(2, '0')}',
    };

    final cubit = context.read<MarketingCubit>();
    final bool success;
    if (_isEdit) {
      success = await cubit.updatePr(widget.prSchedule!.id, data);
    } else {
      success = await cubit.createPr(data);
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'PR content berhasil diperbarui'
              : 'PR content berhasil dibuat'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Gagal memperbarui PR content'
              : 'Gagal membuat PR content'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Bar ──────────────────────────────────────────────
          Row(
            children: [
              IconButton.outlined(
                onPressed: _isSubmitting ? null : () => context.pop(),
                icon:
                    const Icon(Icons.arrow_back, size: AppDimensions.iconMd),
                tooltip: 'Kembali',
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit
                          ? 'Edit PR Content'
                          : 'Tambah PR Content Baru',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      _isEdit
                          ? 'Perbarui data PR content'
                          : 'Isi data untuk membuat PR content baru',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),

          // ── Form Card ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppDimensions.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Informasi PR'),
                  const SizedBox(height: AppDimensions.md),

                  // Title
                  TextFormField(
                    controller: _titleCtrl,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Judul *',
                      hintText: 'Masukkan judul PR content',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Judul wajib diisi';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Row: Type + Status
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _type,
                          decoration: const InputDecoration(
                            labelText: 'Tipe *',
                          ),
                          items: _typeOptions.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: _isSubmitting
                              ? null
                              : (v) => setState(
                                  () => _type = v ?? 'press_release'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: _statusOptions.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: _isSubmitting || !_isEdit
                              ? null
                              : (v) => setState(
                                  () => _status = v ?? 'draft'),
                          disabledHint: const Text('Draft'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Row: Media/Venue + PIC Name
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mediaVenueCtrl,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Media / Venue',
                            hintText: 'Nama media atau venue',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: TextFormField(
                          controller: _picNameCtrl,
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'PIC',
                            hintText: 'Nama penanggung jawab',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Scheduled At
                  GestureDetector(
                    onTap: _isSubmitting ? null : _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        enabled: !_isSubmitting,
                        decoration: InputDecoration(
                          labelText: 'Jadwal',
                          hintText: 'Pilih tanggal',
                          suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: AppDimensions.iconMd),
                        ),
                        controller: TextEditingController(
                          text: _scheduledAt != null
                              ? '${_scheduledAt!.day.toString().padLeft(2, '0')}/'
                                  '${_scheduledAt!.month.toString().padLeft(2, '0')}/'
                                  '${_scheduledAt!.year}'
                              : '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Notes
                  TextFormField(
                    controller: _notesCtrl,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      hintText: 'Catatan tambahan (opsional)',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // ── Action Buttons ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => context.pop(),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppDimensions.xs),
        const Divider(color: AppColors.border),
      ],
    );
  }
}
