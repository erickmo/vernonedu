import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/public_certificate_verification_model.dart';
import '../../core/services/public_certificate_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/navbar_widget.dart';

/// Public PII-safe certificate verification page.
/// Routes:
///   /sertifikat              → manual input
///   /sertifikat/:code        → auto-verify from QR
///   /sertifikat?code=...     → auto-verify from query string
class SertifikatPage extends StatefulWidget {
  /// Empty when accessed via /sertifikat without param.
  final String code;
  const SertifikatPage({super.key, required this.code});

  @override
  State<SertifikatPage> createState() => _SertifikatPageState();
}

enum _ViewState { idle, loading, valid, revoked, notFound, error }

class _SertifikatPageState extends State<SertifikatPage> {
  final _service = PublicCertificateService();
  final _codeCtrl = TextEditingController();

  _ViewState _state = _ViewState.idle;
  PublicCertificateVerification? _cert;

  @override
  void initState() {
    super.initState();
    final initial = _initialCode();
    if (initial.isNotEmpty) {
      _codeCtrl.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify(initial));
    }
  }

  String _initialCode() {
    if (widget.code.isNotEmpty) return widget.code.toUpperCase();
    final qp = Uri.base.queryParameters['code'];
    return (qp ?? '').toUpperCase();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    setState(() => _state = _ViewState.loading);
    try {
      final c = await _service.verifyCertificate(trimmed);
      if (!mounted) return;
      setState(() {
        _cert = c;
        _state = c.isRevoked ? _ViewState.revoked : _ViewState.valid;
      });
    } on CertificateNotFoundException {
      if (!mounted) return;
      setState(() => _state = _ViewState.notFound);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _ViewState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebScaffold(
      body: Column(
        children: [
          _Hero(codeCtrl: _codeCtrl, onVerify: () => _verify(_codeCtrl.text)),
          _Body(state: _state, cert: _cert),
          const FooterWidget(),
        ],
      ),
    );
  }
}

// ─── Hero ───────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final TextEditingController codeCtrl;
  final VoidCallback onVerify;
  const _Hero({required this.codeCtrl, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal:
            isMobile ? AppDimensions.s24 : Responsive.sectionPaddingH(context),
        vertical: AppDimensions.s64,
      ),
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Column(
        children: [
          Text(
            'Verifikasi Sertifikat VernonEdu',
            style: isMobile ? AppTextStyles.displayM : AppTextStyles.displayL,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: AppDimensions.s16),
          Text(
            'Masukkan kode sertifikat untuk memverifikasi keasliannya.',
            style:
                AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: AppDimensions.s32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _CodeInput(ctrl: codeCtrl, onVerify: onVerify),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _CodeInput extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onVerify;
  const _CodeInput({required this.ctrl, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final field = TextField(
      controller: ctrl,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [_UpperCaseFormatter()],
      style: AppTextStyles.bodyM.copyWith(color: Colors.white),
      onSubmitted: (_) => onVerify(),
      decoration: InputDecoration(
        hintText: 'Contoh: VEDU-2026-AB12CD',
        hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
    final btn = ElevatedButton(
      onPressed: onVerify,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandPurple,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r12),
        ),
        elevation: 0,
      ),
      child: Text('Verifikasi', style: AppTextStyles.labelL),
    );
    if (isMobile) {
      return Column(children: [field, const SizedBox(height: 12), SizedBox(width: double.infinity, child: btn)]);
    }
    return Row(children: [Expanded(child: field), const SizedBox(width: 12), btn]);
  }
}

// ─── Body ───────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final _ViewState state;
  final PublicCertificateVerification? cert;
  const _Body({required this.state, required this.cert});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _ViewState.idle:
        return const _IdleSection();
      case _ViewState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator()),
        );
      case _ViewState.valid:
      case _ViewState.revoked:
        return _ResultSection(cert: cert!);
      case _ViewState.notFound:
        return const _MessageSection(
          icon: Icons.search_off_rounded,
          color: AppColors.error,
          title: 'Sertifikat Tidak Ditemukan',
          message:
              'Sertifikat tidak ditemukan. Periksa kembali kode yang dimasukkan.',
        );
      case _ViewState.error:
        return const _MessageSection(
          icon: Icons.cloud_off_rounded,
          color: AppColors.error,
          title: 'Gagal Memverifikasi',
          message: 'Terjadi kesalahan. Silakan coba lagi.',
        );
    }
  }
}

class _IdleSection extends StatelessWidget {
  const _IdleSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      color: AppColors.bgPrimary,
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_rounded,
                size: 64, color: AppColors.brandPurple),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'Masukkan kode sertifikat di atas untuk memulai verifikasi.',
              style: AppTextStyles.bodyM
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  const _MessageSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      color: AppColors.bgPrimary,
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: AppDimensions.s24),
            Text(title,
                style: AppTextStyles.h3.copyWith(color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.s8),
            Text(message,
                style: AppTextStyles.bodyM
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Result ─────────────────────────────────────────────────────────────────

class _ResultSection extends StatelessWidget {
  final PublicCertificateVerification cert;
  const _ResultSection({required this.cert});

  @override
  Widget build(BuildContext context) {
    final isValid = cert.isValid && !cert.isRevoked;
    final color = isValid ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      color: AppColors.bgPrimary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.s32),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppDimensions.r24),
              border:
                  Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              children: [
                Icon(
                  isValid ? Icons.verified_rounded : Icons.cancel_outlined,
                  size: 56,
                  color: color,
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: AppDimensions.s16),
                Text(
                  isValid ? 'Sertifikat Valid' : 'Sertifikat Dicabut',
                  style: AppTextStyles.h2.copyWith(color: color),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.s24),
                const Divider(),
                const SizedBox(height: AppDimensions.s16),
                _Field(label: 'Kode', value: cert.code),
                _Field(label: 'Jenis', value: cert.typeLabel),
                _Field(
                    label: 'Tanggal Terbit',
                    value: _fmt(cert.issuedAt)),
                if (cert.isRevoked && cert.revokedAt != null)
                  _Field(
                      label: 'Tanggal Dicabut',
                      value: _fmt(cert.revokedAt!)),
                if (cert.isRevoked && cert.revokeReason != null)
                  _Field(label: 'Alasan', value: cert.revokeReason!),
                const SizedBox(height: AppDimensions.s8),
                Text(
                  'Demi privasi, detail pemilik sertifikat tidak ditampilkan di halaman publik.',
                  style: AppTextStyles.bodyS
                      .copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      DateFormat('d MMM y', 'id_ID').format(d);
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: AppTextStyles.labelM)),
          Text(': ', style: AppTextStyles.labelM),
          Expanded(child: Text(value, style: AppTextStyles.bodyM)),
        ],
      ),
    );
  }
}
