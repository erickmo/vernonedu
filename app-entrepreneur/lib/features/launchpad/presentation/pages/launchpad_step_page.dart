import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../widgets/trackable_item_widget.dart';

/// Konfigurasi step launchpad.
class _StepConfig {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<_StepField> fields;
  final List<String> checklist;
  final bool isTrackable;
  final String? trackableItemLabel;
  final String? trackableAddLabel;
  final List<String>? trackableDefaultTodos;

  const _StepConfig({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.fields,
    required this.checklist,
    this.isTrackable = false,
    this.trackableItemLabel,
    this.trackableAddLabel,
    this.trackableDefaultTodos,
  });
}

class _StepField {
  final String label;
  final String hint;
  final int maxLines;

  const _StepField({
    required this.label,
    required this.hint,
    this.maxLines = 4,
  });
}

/// Form page per tahapan launchpad.
/// - Key Partners, Key Activities, Key Resources → TrackableListWidget
/// - Lainnya → form + checklist biasa
class LaunchpadStepPage extends StatefulWidget {
  final String businessId;
  final String stepKey;

  const LaunchpadStepPage({
    super.key,
    required this.businessId,
    required this.stepKey,
  });

  @override
  State<LaunchpadStepPage> createState() => _LaunchpadStepPageState();
}

class _LaunchpadStepPageState extends State<LaunchpadStepPage> {
  final _formKey = GlobalKey<FormState>();
  late final _StepConfig _config;
  late final Map<String, TextEditingController> _controllers;
  late final List<bool> _checklistState;

  static const _configs = {
    'business-profile': _StepConfig(
      title: 'Business Profile',
      description: 'Identitas resmi bisnis kamu.',
      icon: Icons.storefront_rounded,
      color: Color(0xFF4D2975),
      fields: [
        _StepField(label: 'Nama Bisnis', hint: 'Nama resmi bisnis kamu', maxLines: 1),
        _StepField(label: 'Tagline', hint: 'Satu kalimat yang menggambarkan bisnis kamu', maxLines: 1),
        _StepField(label: 'Deskripsi Bisnis', hint: 'Jelaskan bisnis kamu dalam 2-3 kalimat (elevator pitch)...'),
        _StepField(label: 'Visi', hint: 'Gambaran besar tentang apa yang ingin dicapai bisnis kamu di masa depan...', maxLines: 3),
        _StepField(label: 'Misi', hint: 'Langkah-langkah konkret untuk mewujudkan visi...'),
      ],
      checklist: [
        'Tentukan nama bisnis resmi',
        'Buat logo atau identitas visual',
        'Tulis deskripsi bisnis (elevator pitch)',
        'Definisikan visi & misi',
        'Buat tagline yang memorable',
      ],
    ),
    'key-partnerships': _StepConfig(
      title: 'Key Partnerships',
      description: 'Identifikasi dan dapatkan partner strategis.',
      icon: Icons.handshake_rounded,
      color: Color(0xFF0168FA),
      fields: [],
      checklist: [],
      isTrackable: true,
      trackableItemLabel: 'Partner',
      trackableAddLabel: 'Tambah Partner Baru',
      trackableDefaultTodos: [
        'Riset profil dan kontak partner',
        'Siapkan proposal kerjasama',
        'Hubungi dan jadwalkan pertemuan',
        'Presentasi proposal',
        'Negosiasi terms & conditions',
        'Finalisasi dan tandatangani kesepakatan',
        'Onboarding dan mulai kerjasama',
      ],
    ),
    'key-activities': _StepConfig(
      title: 'Key Activities',
      description: 'Susun aktivitas utama bisnis beserta SOP.',
      icon: Icons.task_alt_rounded,
      color: Color(0xFF10B759),
      fields: [],
      checklist: [],
      isTrackable: true,
      trackableItemLabel: 'Aktivitas',
      trackableAddLabel: 'Tambah Aktivitas Baru',
      trackableDefaultTodos: [
        'Definisikan scope dan tujuan aktivitas',
        'Tentukan PIC (person in charge)',
        'Identifikasi tools/resources yang dibutuhkan',
        'Tentukan frekuensi (harian/mingguan/bulanan)',
        'Buat SOP/langkah-langkah pelaksanaan',
        'Setup tracking/monitoring',
        'Jalankan dan evaluasi',
      ],
    ),
    'key-resources': _StepConfig(
      title: 'Key Resources',
      description: 'Identifikasi dan akuisisi sumber daya.',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFFFF6F00),
      fields: [],
      checklist: [],
      isTrackable: true,
      trackableItemLabel: 'Resource',
      trackableAddLabel: 'Tambah Resource Baru',
      trackableDefaultTodos: [
        'Identifikasi kebutuhan spesifik',
        'Estimasi biaya/budget',
        'Cari sumber akuisisi (beli/sewa/rekrut)',
        'Bandingkan opsi dan pilih yang terbaik',
        'Mulai proses akuisisi',
        'Verifikasi resource tersedia dan siap',
        'Integrasikan ke operasional bisnis',
      ],
    ),
    'channels': _StepConfig(
      title: 'Channels',
      description: 'Setup channel distribusi dan komunikasi.',
      icon: Icons.share_rounded,
      color: Color(0xFF1DA1F2),
      fields: [],
      checklist: [],
      isTrackable: true,
      trackableItemLabel: 'Channel',
      trackableAddLabel: 'Tambah Channel Baru',
      trackableDefaultTodos: [
        'Riset channel dan target audience',
        'Buat akun / setup channel',
        'Siapkan branding & profile',
        'Buat content plan',
        'Siapkan materi/content awal',
        'Test alur customer journey',
        'Tentukan KPI dan mulai monitoring',
      ],
    ),
    'product-service': _StepConfig(
      title: 'Product / Service Setup',
      description: 'Detail produk atau jasa, pricing, dan katalog.',
      icon: Icons.category_rounded,
      color: Color(0xFFDC3545),
      fields: [
        _StepField(label: 'Detail Produk/Jasa', hint: 'Nama, spesifikasi, ukuran, varian, fitur utama...', maxLines: 6),
        _StepField(label: 'Pricing Strategy', hint: 'Strategi pricing dan harga per item...'),
        _StepField(label: 'Packaging & Presentation', hint: 'Bagaimana produk dikemas atau jasa dipresentasikan?'),
        _StepField(label: 'Stok Awal / Kapasitas', hint: 'Berapa stok awal atau kapasitas layanan?'),
      ],
      checklist: [
        'Finalisasi detail produk/jasa',
        'Tentukan pricing strategy dan harga jual',
        'Siapkan packaging atau presentation',
        'Buat katalog produk/jasa',
        'Siapkan stok awal atau kapasitas layanan',
        'Test quality produk/jasa sebelum launch',
      ],
    ),
    'launch-plan': _StepConfig(
      title: 'Launch Plan',
      description: 'Timeline peluncuran dan milestone.',
      icon: Icons.event_note_rounded,
      color: Color(0xFF6F42C1),
      fields: [
        _StepField(label: 'Target Tanggal Launch', hint: 'Kapan bisnis kamu akan diluncurkan?', maxLines: 1),
        _StepField(label: 'Timeline Mundur', hint: 'T-30: ...\nT-14: ...\nT-7: ...\nT-3: ...\nT-1: ...\nD-Day: ...', maxLines: 8),
        _StepField(label: 'Launch Campaign', hint: 'Rencana promosi: teaser, countdown, pre-order...'),
        _StepField(label: 'Contingency Plan', hint: 'Rencana cadangan jika ada masalah saat launch?'),
      ],
      checklist: [
        'Tentukan tanggal target launch',
        'Buat timeline mundur',
        'Set milestone per minggu',
        'Siapkan launch campaign',
        'Koordinasi dengan partner dan tim',
        'Dry run / simulasi operasional',
        'Siapkan contingency plan',
      ],
    ),
    'go-live': _StepConfig(
      title: 'Go Live',
      description: 'Review final dan luncurkan bisnis!',
      icon: Icons.rocket_rounded,
      color: Color(0xFF10B759),
      fields: [
        _StepField(label: 'Final Review Notes', hint: 'Catatan review final sebelum launch...', maxLines: 6),
        _StepField(label: 'Launch Day Plan', hint: 'Timeline per jam di hari peluncuran...', maxLines: 6),
        _StepField(label: 'First Week Plan', hint: 'Rencana minggu pertama: monitoring, feedback, adjustment...'),
      ],
      checklist: [
        'Review semua tahapan sudah complete',
        'Final check semua channel aktif',
        'Final check stok/kapasitas siap',
        'Final check tim siap operasional',
        'Publish dan umumkan ke publik',
        'Monitor feedback customer pertama',
      ],
    ),
  };

  @override
  void initState() {
    super.initState();
    _config = _configs[widget.stepKey] ?? _configs['business-profile']!;
    _controllers = {
      for (final field in _config.fields) field.label: TextEditingController(),
    };
    _checklistState = List.filled(_config.checklist.length, false);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _checkedCount => _checklistState.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBreadcrumb(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildHeader(),
          const SizedBox(height: AppDimensions.spacingL),
          if (_config.isTrackable)
            _buildTrackableContent()
          else
            _buildFormAndChecklist(context),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/launchpad'),
          child: Text(
            'Launchpad',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
        ),
        const _Sep(),
        InkWell(
          onTap: () => context.go('/launchpad/${widget.businessId}'),
          child: Text(
            'Bisnis 001',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
          ),
        ),
        const _Sep(),
        Text(
          _config.title,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_config.color, _config.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(_config.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _config.title,
                  style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _config.description,
                  style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TRACKABLE CONTENT (Key Partners, Activities, Resources, Channels) ───

  Widget _buildTrackableContent() {
    return TrackableListWidget(
      title: _config.title,
      subtitle: _config.description,
      icon: _config.icon,
      color: _config.color,
      itemLabel: _config.trackableItemLabel ?? 'Item',
      addButtonLabel: _config.trackableAddLabel ?? 'Tambah Item',
      defaultTodos: _config.trackableDefaultTodos ?? [],
    );
  }

  // ─── FORM + CHECKLIST CONTENT (other steps) ─────────────────

  Widget _buildFormAndChecklist(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointDesktop;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: _buildFormSection()),
          const SizedBox(width: AppDimensions.spacingL),
          Expanded(flex: 4, child: _buildChecklistSection()),
        ],
      );
    }

    return Column(
      children: [
        _buildChecklistSection(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildFormSection(),
      ],
    );
  }

  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Worksheet',
            style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ..._config.fields.map((field) => _buildFieldCard(field)),
          const SizedBox(height: AppDimensions.spacingL),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildFieldCard(_StepField field) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: _config.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                field.label,
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _controllers[field.label],
            maxLines: field.maxLines,
            style: GoogleFonts.inter(fontSize: 13, height: 1.6),
            decoration: InputDecoration(
              hintText: field.hint,
              hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint, height: 1.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                borderSide: BorderSide(color: _config.color, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: _config.color, size: 20),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'Checklist',
                style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _config.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  '$_checkedCount/${_config.checklist.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _config.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            child: LinearProgressIndicator(
              value: _config.checklist.isNotEmpty
                  ? _checkedCount / _config.checklist.length
                  : 0,
              minHeight: 6,
              backgroundColor: _config.color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_config.color),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ...List.generate(_config.checklist.length, (index) {
            final isChecked = _checklistState[index];
            return InkWell(
              onTap: () => setState(() {
                _checklistState[index] = !_checklistState[index];
              }),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 20,
                      color: isChecked ? _config.color : AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _config.checklist[index],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isChecked ? AppColors.textSecondary : AppColors.textPrimary,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft tersimpan')),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
            ),
            child: Text('Simpan Draft',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tahapan berhasil disimpan!'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.go('/launchpad/${widget.businessId}');
              }
            },
            child: Text('Submit',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
    );
  }
}
