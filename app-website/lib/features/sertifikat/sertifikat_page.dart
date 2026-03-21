import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/public_certificate_model.dart';
import '../../core/services/public_certificate_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/navbar_widget.dart';

/// Certificate verification page.
/// - /sertifikat        → manual code input
/// - /sertifikat/:code  → auto-verify from QR
class SertifikatPage extends StatefulWidget {
  /// Empty string when accessed from /sertifikat (manual input mode).
  final String code;

  const SertifikatPage({super.key, required this.code});

  @override
  State<SertifikatPage> createState() => _SertifikatPageState();
}

class _SertifikatPageState extends State<SertifikatPage> {
  final _service = PublicCertificateService();
  final _codeCtrl = TextEditingController();
  CertificateVerification? _cert;
  bool _loading = false;
  String? _error;
  bool _searched = false;

  bool get _isManualMode => widget.code.isEmpty;

  @override
  void initState() {
    super.initState();
    if (!_isManualMode) {
      _codeCtrl.text = widget.code;
      _verify(widget.code);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (code.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _cert = null;
      _searched = true;
    });
    try {
      final c = await _service.verifyCertificate(code.trim());
      if (mounted) setState(() { _cert = c; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Sertifikat tidak ditemukan. Pastikan kode yang dimasukkan sudah benar.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      body: Column(
        children: [
          _HeroSection(
            code: _isManualMode ? null : widget.code,
            codeCtrl: _codeCtrl,
            isManualMode: _isManualMode,
            onVerify: () => _verify(_codeCtrl.text),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _InvalidSection(message: _error!)
          else if (_cert != null)
            _ResultSection(cert: _cert!)
          else if (!_isManualMode && _searched)
            const SizedBox.shrink(),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// ─── Hero ───────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String? code;
  final TextEditingController codeCtrl;
  final bool isManualMode;
  final VoidCallback onVerify;

  const _HeroSection({
    required this.code,
    required this.codeCtrl,
    required this.isManualMode,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? AppDimensions.s24
            : Responsive.sectionPaddingH(context),
        vertical: AppDimensions.s64,
      ),
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Column(
        children: [
          Text(
            'Verifikasi Sertifikat',
            style: isMobile ? AppTextStyles.displayM : AppTextStyles.displayL,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: AppDimensions.s16),
          if (code != null && code!.isNotEmpty) ...[
            Text(
              'Kode: $code',
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.brandPurple,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          ] else ...[
            Text(
              'Masukkan kode sertifikat untuk memverifikasi keasliannya.',
              style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: AppDimensions.s32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _CodeInputField(ctrl: codeCtrl, onVerify: onVerify),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          ],
        ],
      ),
    );
  }
}

// ─── Code Input ─────────────────────────────────────────────────────────────

class _CodeInputField extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onVerify;

  const _CodeInputField({required this.ctrl, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            style: AppTextStyles.bodyM.copyWith(color: Colors.white),
            onSubmitted: (_) => onVerify(),
            decoration: InputDecoration(
              hintText: 'Masukkan kode sertifikat',
              hintStyle:
                  AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppDimensions.r12),
                ),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppDimensions.r12),
                ),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppDimensions.r12),
                ),
                borderSide: const BorderSide(color: AppColors.brandPurple),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onVerify,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(AppDimensions.r12),
              ),
            ),
            elevation: 0,
          ),
          child: Text('Verifikasi', style: AppTextStyles.labelL),
        ),
      ],
    );
  }
}

// ─── Result Section ──────────────────────────────────────────────────────────

class _ResultSection extends StatelessWidget {
  final CertificateVerification cert;

  const _ResultSection({required this.cert});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isValid = cert.isValid && !cert.isRevoked;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? AppDimensions.s24
            : Responsive.sectionPaddingH(context),
        vertical: AppDimensions.s64,
      ),
      color: AppColors.bgPrimary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Stack(
            children: [
              // Certificate card
              Container(
                padding: const EdgeInsets.all(AppDimensions.s40),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(AppDimensions.r24),
                  border: Border.all(
                    color: isValid
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.error.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isValid
                              ? AppColors.success
                              : AppColors.error)
                          .withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: (isValid
                                ? AppColors.success
                                : AppColors.error)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isValid
                            ? Icons.verified_rounded
                            : Icons.cancel_outlined,
                        size: 36,
                        color: isValid
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ).animate().scale(duration: 400.ms),
                    const SizedBox(height: AppDimensions.s24),
                    Text(
                      isValid
                          ? 'Sertifikat Valid'
                          : cert.isRevoked
                              ? 'Sertifikat Dicabut'
                              : 'Sertifikat Tidak Valid',
                      style: AppTextStyles.h2.copyWith(
                        color: isValid
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    if (cert.isRevoked && cert.revokeReason != null) ...[
                      const SizedBox(height: AppDimensions.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Alasan: ${cert.revokeReason}',
                          style: AppTextStyles.bodyS.copyWith(
                              color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppDimensions.s32),
                    const Divider(color: Colors.white12),
                    const SizedBox(height: AppDimensions.s24),
                    _CertField(label: 'Nama Peserta', value: cert.studentName),
                    const SizedBox(height: AppDimensions.s16),
                    _CertField(label: 'Kursus', value: cert.courseName),
                    if (cert.batchName != null) ...[
                      const SizedBox(height: AppDimensions.s16),
                      _CertField(label: 'Kelas', value: cert.batchName!),
                    ],
                    const SizedBox(height: AppDimensions.s16),
                    _CertField(label: 'Jenis', value: cert.typeLabel),
                    const SizedBox(height: AppDimensions.s16),
                    _CertField(
                        label: 'Tanggal Terbit',
                        value: _fmtDate(cert.issueDate)),
                    if (cert.expiryDate != null) ...[
                      const SizedBox(height: AppDimensions.s16),
                      _CertField(
                          label: 'Berlaku Hingga',
                          value: _fmtDate(cert.expiryDate!)),
                    ],
                    const SizedBox(height: AppDimensions.s16),
                    _CertField(label: 'Nomor Sertifikat', value: cert.code),
                    const SizedBox(height: AppDimensions.s16),
                    _CertField(label: 'Penerbit', value: cert.issuerName),
                  ],
                ),
              ),
              // Revoked watermark overlay
              if (cert.isRevoked) const _RevokedWatermark(),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(String raw) {
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

// ─── Revoked Watermark ──────────────────────────────────────────────────────

class _RevokedWatermark extends StatelessWidget {
  const _RevokedWatermark();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.r24),
        child: IgnorePointer(
          child: Center(
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.6),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SERTIFIKAT DICABUT',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.error.withValues(alpha: 0.5),
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Cert Field ─────────────────────────────────────────────────────────────

class _CertField extends StatelessWidget {
  final String label;
  final String value;

  const _CertField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(label, style: AppTextStyles.labelM),
        ),
        Text(': ', style: AppTextStyles.labelM),
        Expanded(child: Text(value, style: AppTextStyles.bodyM)),
      ],
    );
  }
}

// ─── Invalid Section ─────────────────────────────────────────────────────────

class _InvalidSection extends StatelessWidget {
  final String message;

  const _InvalidSection({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? AppDimensions.s24
            : Responsive.sectionPaddingH(context),
        vertical: AppDimensions.s80,
      ),
      color: AppColors.bgPrimary,
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 36, color: AppColors.error),
            ),
            const SizedBox(height: AppDimensions.s24),
            Text(
              'Sertifikat Tidak Ditemukan',
              style: AppTextStyles.h3.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.s8),
            Text(
              message,
              style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
