import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/certificate_entity.dart';
import '../cubit/student_certificates_cubit.dart';
import 'certificate_list_view.dart';
import 'certificate_revoke_dialog.dart';

/// Self-contained section that loads + renders certificates for one student.
/// Drop directly into a detail page; provides its own [BlocProvider].
class StudentCertificatesTab extends StatelessWidget {
  final String studentId;

  const StudentCertificatesTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<StudentCertificatesCubit>()..load(studentId),
      child: const _StudentCertificatesView(),
    );
  }
}

class _StudentCertificatesView extends StatelessWidget {
  const _StudentCertificatesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudentCertificatesCubit, StudentCertificatesState>(
      builder: (context, state) {
        if (state is StudentCertificatesLoading ||
            state is StudentCertificatesInitial) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is StudentCertificatesError) {
          return _ErrorView(message: state.message);
        }
        if (state is StudentCertificatesLoaded) {
          return _LoadedView(items: state.items);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  final List<CertificateEntity> items;
  const _LoadedView({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _emptyCard();
    }
    final participants =
        items.where((c) => c.isParticipant).toList(growable: false);
    final competencies =
        items.where((c) => c.isCompetency).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (participants.isNotEmpty) ...[
          _GroupHeader(
              title: 'Sertifikat Partisipan', count: participants.length),
          const SizedBox(height: AppDimensions.sm),
          _list(context, participants),
          const SizedBox(height: AppDimensions.md),
        ],
        if (competencies.isNotEmpty) ...[
          _GroupHeader(
              title: 'Sertifikat Kompetensi', count: competencies.length),
          const SizedBox(height: AppDimensions.sm),
          _list(context, competencies),
        ],
      ],
    );
  }

  Widget _list(BuildContext context, List<CertificateEntity> list) {
    return CertificateListView(
      items: list,
      onView: (c) => _showCertificateDetail(context, c),
      onRevoke: (c) => _handleRevoke(context, c),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 32, color: AppColors.textHint),
          SizedBox(height: AppDimensions.sm),
          Text('Belum ada sertifikat',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

Future<void> _handleRevoke(
    BuildContext context, CertificateEntity cert) async {
  final cubit = context.read<StudentCertificatesCubit>();
  final reason =
      await showCertificateRevokeDialog(context, certificate: cert);
  if (reason == null) return;
  final ok =
      await cubit.revoke(certificateId: cert.id, reason: reason);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ok
          ? 'Pengajuan pencabutan terkirim'
          : 'Gagal mengajukan pencabutan'),
      backgroundColor: ok ? AppColors.success : AppColors.error,
    ),
  );
}

void _showCertificateDetail(BuildContext context, CertificateEntity c) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(c.certificateCode),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Tipe', c.isCompetency ? 'Kompetensi' : 'Partisipan'),
            _kv('Status', c.isRevoked ? 'Dicabut' : 'Aktif'),
            _kv('Pemegang',
                c.studentName.isEmpty ? c.studentId : c.studentName),
            _kv('Course', c.courseName.isEmpty ? c.courseId : c.courseName),
            if (c.batchName.isNotEmpty) _kv('Batch', c.batchName),
            _kv('Diterbitkan', _fmt(c.issuedAt)),
            if (c.revokedAt != null) _kv('Dicabut', _fmt(c.revokedAt!)),
            if (c.revocationReason != null && c.revocationReason!.isNotEmpty)
              _kv('Alasan', c.revocationReason!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

Widget _kv(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 100,
              child: Text(k,
                  style:
                      const TextStyle(color: AppColors.textSecondary))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );

class _GroupHeader extends StatelessWidget {
  final String title;
  final int count;

  const _GroupHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        const SizedBox(width: AppDimensions.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
          child: Text('$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: AppDimensions.iconMd, color: AppColors.error),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}
