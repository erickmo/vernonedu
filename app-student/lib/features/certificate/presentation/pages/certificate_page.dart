import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

// ─── DATA ─────────────────────────────────────────────────────────────────────

class _CertificateData {
  final String id;
  final String courseName;
  final String batchCode;
  final String field;
  final String issueDate;
  final double score;
  final String grade;
  final String certNumber;

  const _CertificateData({
    required this.id,
    required this.courseName,
    required this.batchCode,
    required this.field,
    required this.issueDate,
    required this.score,
    required this.grade,
    required this.certNumber,
  });
}

const _mockCertificates = [
  _CertificateData(
    id: '1', courseName: 'Entrepreneurship Dasar',
    batchCode: 'ENT-2025-03', field: 'Bisnis',
    issueDate: '15 Des 2025', score: 92.5, grade: 'A',
    certNumber: 'VE/2025/ENT/001/001',
  ),
  _CertificateData(
    id: '2', courseName: 'Barbershop Profesional',
    batchCode: 'BB-2025-02', field: 'Barbershop',
    issueDate: '30 Nov 2025', score: 85.0, grade: 'B',
    certNumber: 'VE/2025/BB/002/045',
  ),
  _CertificateData(
    id: '3', courseName: 'Tata Boga & Kuliner',
    batchCode: 'TB-2025-04', field: 'Kuliner',
    issueDate: '10 Okt 2025', score: 78.5, grade: 'B',
    certNumber: 'VE/2025/TB/004/023',
  ),
];

// ─── PAGE ─────────────────────────────────────────────────────────────────────

class CertificatePage extends StatelessWidget {
  const CertificatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(AppStrings.certificateTitle),
      ),
      body: _mockCertificates.isEmpty
          ? const _EmptyCertificate()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildSummaryHeader(context)),
                SliverPadding(
                  padding: const EdgeInsets.all(AppDimensions.pagePadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _CertificateCard(cert: _mockCertificates[i]),
                      childCount: _mockCertificates.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context) => Container(
        margin: const EdgeInsets.all(AppDimensions.pagePadding),
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pencapaianmu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    '${_mockCertificates.length} sertifikat berhasil diraih',
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 32, color: Colors.white),
            ),
          ],
        ),
      );
}

// ─── CERTIFICATE CARD ─────────────────────────────────────────────────────────

class _CertificateCard extends StatelessWidget {
  final _CertificateData cert;
  const _CertificateCard({required this.cert});

  Color get _gradeColor {
    switch (cert.grade) {
      case 'A': return AppColors.gradeA;
      case 'B': return AppColors.gradeB;
      default: return AppColors.gradeC;
    }
  }

  IconData get _gradeIcon {
    switch (cert.grade) {
      case 'A': return Icons.military_tech_rounded;
      case 'B': return Icons.emoji_events_rounded;
      default: return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          _buildCertHeader(),
          _buildCertBody(context),
        ],
      ),
    );
  }

  Widget _buildCertHeader() => Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary.withValues(alpha: 0.08), AppColors.primary.withValues(alpha: 0.03)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusLg),
            topRight: Radius.circular(AppDimensions.radiusLg),
          ),
        ),
        child: Row(
          children: [
            // Certificate icon with grade badge
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 28, color: AppColors.primary),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _gradeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        cert.grade,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: cert.grade == 'A' ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.courseName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(cert.batchCode, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(_gradeIcon, size: 24, color: _gradeColor),
          ],
        ),
      );

  Widget _buildCertBody(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildInfoItem('Nilai', '${cert.score}', AppColors.primary)),
                Expanded(child: _buildInfoItem('Grade', cert.grade, _gradeColor)),
                Expanded(
                  child: _buildInfoItem(AppStrings.issued, cert.issueDate, AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.numbers_rounded, size: 14, color: AppColors.textHint),
                  const SizedBox(width: AppDimensions.xs),
                  Expanded(
                    child: Text(
                      cert.certNumber,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text('Bagikan', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text(AppStrings.download, style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildInfoItem(String label, String value, Color valueColor) => Column(
        children: [
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
}

class _EmptyCertificate extends StatelessWidget {
  const _EmptyCertificate();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: const Icon(Icons.workspace_premium_outlined, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.md),
          const Text(
            AppStrings.noCertificate,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.xs),
          const Text(
            'Selesaikan kelas untuk mendapatkan sertifikat',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
