import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/public_course_model.dart';
import '../../core/models/public_enrollment_model.dart';
import '../../core/router/app_router.dart';
import '../../core/services/public_course_service.dart';
import '../../core/services/public_enrollment_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/navbar_widget.dart';

/// Enrollment flow — 4 steps:
/// 1. Review Batch  2. Data Diri  3. Pembayaran  4. Konfirmasi
class EnrollmentPage extends StatefulWidget {
  final String batchId;

  const EnrollmentPage({super.key, required this.batchId});

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  final _courseService = PublicCourseService();
  final _enrollService = PublicEnrollmentService();

  PublicBatch? _batch;
  bool _loadingBatch = true;

  // Stepper
  int _step = 0;

  // Step 2 — Data Diri
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _validatingReferral = false;
  String? _referralPartnerName;
  String? _validatedReferralCode;

  // Step 3 — Payment
  String? _selectedPaymentMethod;

  // Step 4 — Result
  bool _submitting = false;
  EnrollmentResponse? _enrollmentResponse;

  @override
  void initState() {
    super.initState();
    _loadBatch();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBatch() async {
    try {
      final b = await _courseService.fetchBatchDetail(widget.batchId);
      if (mounted) {
        setState(() {
          _batch = b;
          _loadingBatch = false;
          _selectedPaymentMethod = b.paymentMethod;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBatch = false);
    }
  }

  Future<void> _validateReferral() async {
    final code = _referralCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _validatingReferral = true);
    final partnerName = await _enrollService.validateReferralCode(code);
    if (mounted) {
      setState(() {
        _validatingReferral = false;
        _referralPartnerName = partnerName;
        _validatedReferralCode = partnerName != null ? code : null;
      });
    }
  }

  Future<void> _submit() async {
    if (_batch == null) return;
    setState(() => _submitting = true);
    try {
      final response = await _enrollService.submitEnrollment(
        EnrollmentRequest(
          batchId: widget.batchId,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
          referralCode: _validatedReferralCode,
          metadata: {
            if (_selectedPaymentMethod != null) 'payment_method': _selectedPaymentMethod,
          },
        ),
      );
      if (mounted) {
        setState(() {
          _submitting = false;
          _enrollmentResponse = response;
          _step = 3;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mendaftar. Silakan coba lagi.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      body: Column(
        children: [
          _buildStepperHeader(context),
          if (_loadingBatch)
            _LoadingSection()
          else if (_batch == null)
            _ErrorSection(onRetry: _loadBatch)
          else
            switch (_step) {
              0 => _Step1ReviewBatch(batch: _batch!, onContinue: () => setState(() => _step = 1)),
              1 => _Step2DataDiri(
                  batch: _batch!,
                  formKey: _formKey,
                  nameCtrl: _nameCtrl,
                  emailCtrl: _emailCtrl,
                  phoneCtrl: _phoneCtrl,
                  addressCtrl: _addressCtrl,
                  referralCtrl: _referralCtrl,
                  validatingReferral: _validatingReferral,
                  referralPartnerName: _referralPartnerName,
                  onValidateReferral: _validateReferral,
                  onBack: () => setState(() => _step = 0),
                  onContinue: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() => _step = 2);
                    }
                  },
                ),
              2 => _Step3Payment(
                  batch: _batch!,
                  selectedMethod: _selectedPaymentMethod,
                  submitting: _submitting,
                  onMethodSelected: (m) => setState(() => _selectedPaymentMethod = m),
                  onBack: () => setState(() => _step = 1),
                  onConfirm: _submit,
                ),
              3 => _Step4Konfirmasi(
                  batch: _batch!,
                  response: _enrollmentResponse,
                  onBrowse: () => context.go(AppRouter.katalog),
                ),
              _ => const SizedBox.shrink(),
            },
          const FooterWidget(),
        ],
      ),
    );
  }

  Widget _buildStepperHeader(BuildContext context) {
    final steps = ['Review Kelas', 'Data Diri', 'Pembayaran', 'Konfirmasi'];
    final isMobile = Responsive.isMobile(context);
    return Container(
      color: AppColors.bgCard,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppDimensions.s24 : AppDimensions.s64,
        vertical: AppDimensions.s24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIdx = i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: AppDimensions.s8),
                    color: stepIdx < _step ? AppColors.brandPurple : AppColors.border,
                  ),
                );
              }
              final idx = i ~/ 2;
              final isActive = idx == _step;
              final isDone = idx < _step;
              return _StepBubble(
                index: idx + 1,
                label: isMobile ? null : steps[idx],
                isActive: isActive,
                isDone: isDone,
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── Step 1: Review Batch ────────────────────────

class _Step1ReviewBatch extends StatelessWidget {
  final PublicBatch batch;
  final VoidCallback onContinue;

  const _Step1ReviewBatch({required this.batch, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPad = isMobile ? AppDimensions.s24 : Responsive.sectionPaddingH(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      color: AppColors.bgPrimary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review Kelas', style: AppTextStyles.h1)
                  .animate()
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: AppDimensions.s8),
              Text(
                'Pastikan detail kelas sudah sesuai sebelum melanjutkan pendaftaran.',
                style: AppTextStyles.bodyM,
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppDimensions.s32),

              // Batch info card
              _InfoCard(
                child: Column(
                  children: [
                    _BatchInfoRow(icon: Icons.school_outlined, label: 'Program', value: batch.courseName),
                    _BatchInfoRow(icon: Icons.category_outlined, label: 'Tipe Kelas', value: batch.courseType),
                    _BatchInfoRow(icon: Icons.person_outline, label: 'Fasilitator', value: batch.facilitatorName),
                    _BatchInfoRow(icon: Icons.location_on_outlined, label: 'Lokasi', value: batch.location),
                    _BatchInfoRow(icon: Icons.calendar_today_outlined, label: 'Tanggal Mulai', value: batch.startDate),
                    if (batch.endDate != null)
                      _BatchInfoRow(icon: Icons.event_outlined, label: 'Tanggal Selesai', value: batch.endDate!),
                    _BatchInfoRow(
                      icon: Icons.event_repeat_outlined,
                      label: 'Jumlah Sesi',
                      value: '${batch.schedules.length} sesi',
                    ),
                    _BatchInfoRow(
                      icon: Icons.people_outline,
                      label: 'Kursi Tersedia',
                      value: '${batch.availableSlots} dari ${batch.maxStudents}',
                      valueColor: batch.isFull ? AppColors.error : AppColors.success,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: AppDimensions.s24),

              // Price + CTA
              Container(
                padding: const EdgeInsets.all(AppDimensions.s24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.r16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biaya Kelas',
                          style: AppTextStyles.labelM.copyWith(color: Colors.white.withOpacity(0.8)),
                        ),
                        const SizedBox(height: AppDimensions.s4),
                        Text(
                          _formatCurrency(batch.price),
                          style: AppTextStyles.h2.copyWith(color: Colors.white),
                        ),
                        Text(
                          _paymentMethodLabel(batch.paymentMethod),
                          style: AppTextStyles.labelS.copyWith(color: Colors.white.withOpacity(0.7)),
                        ),
                      ],
                    ),
                    if (batch.isFull)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(AppDimensions.r8),
                        ),
                        child: const Text('Kelas Penuh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.brandPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.r12)),
                          elevation: 0,
                        ),
                        onPressed: onContinue,
                        child: const Text('Lanjutkan Pendaftaran', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── Step 2: Data Diri ────────────────────────

class _Step2DataDiri extends StatelessWidget {
  final PublicBatch batch;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController referralCtrl;
  final bool validatingReferral;
  final String? referralPartnerName;
  final VoidCallback onValidateReferral;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _Step2DataDiri({
    required this.batch,
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.referralCtrl,
    required this.validatingReferral,
    this.referralPartnerName,
    required this.onValidateReferral,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPad = isMobile ? AppDimensions.s24 : Responsive.sectionPaddingH(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      color: AppColors.bgPrimary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data Diri', style: AppTextStyles.h1).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: AppDimensions.s8),
              Text(
                'Isi data diri Anda untuk mendaftar kelas ${batch.courseName}.',
                style: AppTextStyles.bodyM,
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppDimensions.s32),

              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EnrollField(
                      label: 'Nama Lengkap *',
                      controller: nameCtrl,
                      hint: 'Masukkan nama lengkap',
                      validator: (v) => (v ?? '').isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: AppDimensions.s20),
                    _EnrollField(
                      label: 'Email *',
                      controller: emailCtrl,
                      hint: 'nama@email.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Email wajib diisi';
                        if (!v!.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimensions.s20),
                    _EnrollField(
                      label: 'No Telepon *',
                      controller: phoneCtrl,
                      hint: '08xx xxxx xxxx',
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v ?? '').isEmpty ? 'No telepon wajib diisi' : null,
                    ),
                    const SizedBox(height: AppDimensions.s20),
                    _EnrollField(
                      label: 'Alamat',
                      controller: addressCtrl,
                      hint: 'Opsional',
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppDimensions.s32),

                    // Referral code section
                    Text('Kode Referral', style: AppTextStyles.h4),
                    const SizedBox(height: AppDimensions.s8),
                    Text(
                      'Punya kode referral? Masukkan di sini.',
                      style: AppTextStyles.bodyM.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: AppDimensions.s12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _EnrollField(
                            label: 'Kode Referral',
                            controller: referralCtrl,
                            hint: 'Opsional',
                            suffixIcon: referralPartnerName != null
                                ? const Icon(Icons.check_circle, color: AppColors.success)
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.s12),
                        Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: validatingReferral
                              ? const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.brandPurple,
                                      ),
                                    ),
                                  ),
                                )
                              : OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    side: const BorderSide(color: AppColors.brandPurple),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.r12)),
                                  ),
                                  onPressed: onValidateReferral,
                                  child: Text(
                                    'Cek',
                                    style: TextStyle(color: AppColors.brandPurple, fontWeight: FontWeight.w600),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (referralPartnerName != null) ...[
                      const SizedBox(height: AppDimensions.s12),
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.s12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppDimensions.r8),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                            const SizedBox(width: AppDimensions.s8),
                            Text(
                              'Direferensikan oleh: $referralPartnerName',
                              style: AppTextStyles.labelM.copyWith(color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppDimensions.s40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: onBack,
                          child: Text(
                            '← Kembali',
                            style: TextStyle(color: AppColors.brandPurple, fontWeight: FontWeight.w600),
                          ),
                        ),
                        GradientButton(
                          label: 'Lanjutkan ke Pembayaran →',
                          onTap: onContinue,
                          height: AppDimensions.btnHeightL,
                          horizontalPadding: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── Step 3: Pembayaran ────────────────────────

class _Step3Payment extends StatelessWidget {
  final PublicBatch batch;
  final String? selectedMethod;
  final bool submitting;
  final ValueChanged<String> onMethodSelected;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  const _Step3Payment({
    required this.batch,
    required this.selectedMethod,
    required this.submitting,
    required this.onMethodSelected,
    required this.onBack,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPad = isMobile ? AppDimensions.s24 : Responsive.sectionPaddingH(context);
    final methods = _availableMethods(batch.paymentMethod);
    final currentMethod = selectedMethod ?? batch.paymentMethod;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s64),
      color: AppColors.bgPrimary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Metode Pembayaran', style: AppTextStyles.h1).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: AppDimensions.s8),
              Text('Pilih cara pembayaran yang sesuai.', style: AppTextStyles.bodyM)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppDimensions.s32),

              // Payment methods
              ...methods.map((m) => _PaymentMethodTile(
                    value: m['value']!,
                    label: m['label']!,
                    description: m['description']!,
                    selected: currentMethod == m['value'],
                    onTap: () => onMethodSelected(m['value']!),
                  )),

              const SizedBox(height: AppDimensions.s32),

              // Invoice preview
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan Invoice', style: AppTextStyles.h4),
                    const SizedBox(height: AppDimensions.s16),
                    _PreviewRow('Program', batch.courseName),
                    _PreviewRow('Mulai', batch.startDate),
                    _PreviewRow('Metode', _paymentMethodLabel(currentMethod)),
                    const Divider(height: AppDimensions.s24),
                    _PreviewRow(
                      'Total Biaya',
                      _formatCurrency(batch.price),
                      bold: true,
                      valueColor: AppColors.brandPurple,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: AppDimensions.s40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: submitting ? null : onBack,
                    child: Text(
                      '← Kembali',
                      style: TextStyle(color: AppColors.brandPurple, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GradientButton(
                    label: submitting ? 'Memproses...' : 'Konfirmasi Pendaftaran ✓',
                    onTap: submitting ? () {} : onConfirm,
                    height: AppDimensions.btnHeightL,
                    horizontalPadding: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _availableMethods(String batchMethod) {
    final all = [
      {'value': 'upfront', 'label': 'Lunas di Awal', 'description': 'Bayar penuh sebelum kelas dimulai. Lebih praktis dan sering mendapat diskon.'},
      {'value': 'scheduled', 'label': 'Cicilan Terjadwal', 'description': 'Bayar secara berkala sesuai jadwal yang sudah ditentukan bersama.'},
      {'value': 'monthly', 'label': 'Bulanan', 'description': 'Bayar setiap bulan selama kelas berlangsung.'},
      {'value': 'batch_lump', 'label': 'Lump Sum Batch', 'description': 'Bayar penuh di akhir batch setelah kelas selesai.'},
      {'value': 'per_session', 'label': 'Per Sesi', 'description': 'Bayar setiap sesi setelah sesi selesai dilaksanakan.'},
    ];
    // For non-upfront batches, only show the configured method
    if (batchMethod == 'upfront') return all;
    return all.where((m) => m['value'] == batchMethod).toList();
  }
}

// ──────────────────────── Step 4: Konfirmasi ────────────────────────

class _Step4Konfirmasi extends StatelessWidget {
  final PublicBatch batch;
  final EnrollmentResponse? response;
  final VoidCallback onBrowse;

  const _Step4Konfirmasi({
    required this.batch,
    required this.response,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPad = isMobile ? AppDimensions.s24 : Responsive.sectionPaddingH(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppDimensions.s96),
      color: AppColors.bgPrimary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 52, color: AppColors.success),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: AppDimensions.s32),
              Text('Pendaftaran Berhasil!', style: AppTextStyles.h1, textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.s16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  'Selamat! Pendaftaran kamu untuk kelas ${batch.courseName} telah berhasil.',
                  style: AppTextStyles.bodyL,
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              const SizedBox(height: AppDimensions.s32),

              // Summary card
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ringkasan', style: AppTextStyles.h4),
                    const SizedBox(height: AppDimensions.s16),
                    _PreviewRow('Program', batch.courseName),
                    _PreviewRow('Fasilitator', batch.facilitatorName),
                    _PreviewRow('Lokasi', batch.location),
                    _PreviewRow('Mulai', batch.startDate),
                    const Divider(height: AppDimensions.s24),
                    _PreviewRow('Biaya', _formatCurrency(batch.price), bold: true, valueColor: AppColors.brandPurple),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

              const SizedBox(height: AppDimensions.s20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16, vertical: AppDimensions.s12),
                decoration: BoxDecoration(
                  color: AppColors.brandPurple.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppDimensions.r8),
                  border: Border.all(color: AppColors.brandPurple.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email_outlined, size: 16, color: AppColors.brandPurple),
                    const SizedBox(width: AppDimensions.s8),
                    Text(
                      'Invoice akan dikirim ke email Anda',
                      style: AppTextStyles.labelM.copyWith(color: AppColors.brandPurple),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              const SizedBox(height: AppDimensions.s48),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppDimensions.s16,
                runSpacing: AppDimensions.s12,
                children: [
                  GradientButton(
                    label: 'Download App Siswa',
                    onTap: () {
                      // TODO: Open Play Store / App Store
                    },
                    height: AppDimensions.btnHeightL,
                    horizontalPadding: 24,
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      side: const BorderSide(color: AppColors.brandPurple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.r12)),
                    ),
                    onPressed: onBrowse,
                    child: Text(
                      'Lihat Kursus Lain',
                      style: TextStyle(color: AppColors.brandPurple, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────── Loading & Error ────────────────────────

class _LoadingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 120),
      child: Center(child: CircularProgressIndicator(color: AppColors.brandPurple)),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorSection({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 120),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppDimensions.s16),
          Text('Kelas tidak ditemukan', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.s8),
          Text('Silakan coba lagi atau pilih kelas lain.', style: AppTextStyles.bodyM),
          const SizedBox(height: AppDimensions.s24),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brandPurple)),
            child: Text('Coba Lagi', style: TextStyle(color: AppColors.brandPurple)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────── Shared sub-widgets ────────────────────────

class _StepBubble extends StatelessWidget {
  final int index;
  final String? label;
  final bool isActive;
  final bool isDone;

  const _StepBubble({
    required this.index,
    this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDone ? AppColors.success : isActive ? AppColors.brandPurple : AppColors.border;
    final fg = (isDone || isActive) ? Colors.white : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text('$index', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        if (label != null) ...[
          const SizedBox(height: AppDimensions.s4),
          Text(
            label!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.s24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppDimensions.r16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BatchInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _BatchInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppDimensions.s12),
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _PreviewRow(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: bold
                ? AppTextStyles.h4.copyWith(color: valueColor ?? AppColors.textPrimary)
                : AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String value;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.value,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppDimensions.s12),
        padding: const EdgeInsets.all(AppDimensions.s16),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandPurple.withOpacity(0.06) : AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          border: Border.all(
            color: selected ? AppColors.brandPurple : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selected ? value : '',
              onChanged: (_) => onTap(),
              activeColor: AppColors.brandPurple,
            ),
            const SizedBox(width: AppDimensions.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelL),
                  const SizedBox(height: AppDimensions.s4),
                  Text(description, style: AppTextStyles.bodyM.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _EnrollField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelM),
        const SizedBox(height: AppDimensions.s8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.bgInput,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.s16,
              vertical: AppDimensions.s16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide: const BorderSide(color: AppColors.brandPurple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.r12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────── Utility functions ────────────────────────

String _formatCurrency(int amount) {
  if (amount == 0) return 'Gratis';
  final formatted = amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return 'Rp $formatted';
}

String _paymentMethodLabel(String method) {
  return switch (method) {
    'upfront' => 'Lunas di Awal',
    'scheduled' => 'Cicilan Terjadwal',
    'monthly' => 'Bulanan',
    'batch_lump' => 'Lump Sum Batch',
    'per_session' => 'Per Sesi',
    _ => method,
  };
}
