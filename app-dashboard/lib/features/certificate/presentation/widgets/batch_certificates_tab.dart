import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/certificate_entity.dart';
import '../cubit/batch_certificates_cubit.dart';
import 'certificate_list_view.dart';
import 'certificate_revoke_dialog.dart';

/// Self-contained section that loads + renders certificates for one batch.
class BatchCertificatesTab extends StatelessWidget {
  final String batchId;

  const BatchCertificatesTab({super.key, required this.batchId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BatchCertificatesCubit>()..load(batchId),
      child: const _BatchCertificatesView(),
    );
  }
}

class _BatchCertificatesView extends StatelessWidget {
  const _BatchCertificatesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BatchCertificatesCubit, BatchCertificatesState>(
      builder: (context, state) {
        if (state is BatchCertificatesLoading ||
            state is BatchCertificatesInitial) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.lg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is BatchCertificatesError) {
          return _Error(message: state.message);
        }
        if (state is BatchCertificatesLoaded) {
          return _Loaded(items: state.items);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _Loaded extends StatelessWidget {
  final List<CertificateEntity> items;
  const _Loaded({required this.items});

  Map<String, List<CertificateEntity>> _groupByStudent() {
    final map = <String, List<CertificateEntity>>{};
    for (final c in items) {
      final key = c.studentName.isNotEmpty ? c.studentName : c.studentId;
      map.putIfAbsent(key, () => []).add(c);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
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
    final groups = _groupByStudent();
    final keys = groups.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final k in keys) ...[
          _GroupHeader(title: k, count: groups[k]!.length),
          const SizedBox(height: AppDimensions.sm),
          CertificateListView(
            items: groups[k]!,
            onView: (c) => _viewDetail(context, c),
            onRevoke: (c) => _handleRevoke(context, c),
          ),
          const SizedBox(height: AppDimensions.md),
        ],
      ],
    );
  }
}

Future<void> _handleRevoke(
    BuildContext context, CertificateEntity cert) async {
  final cubit = context.read<BatchCertificatesCubit>();
  final reason =
      await showCertificateRevokeDialog(context, certificate: cert);
  if (reason == null) return;
  final ok = await cubit.revoke(certificateId: cert.id, reason: reason);
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

void _viewDetail(BuildContext context, CertificateEntity c) {
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
            _kv('Diterbitkan',
                '${c.issuedAt.day}/${c.issuedAt.month}/${c.issuedAt.year}'),
            if (c.revokedAt != null)
              _kv('Dicabut',
                  '${c.revokedAt!.day}/${c.revokedAt!.month}/${c.revokedAt!.year}'),
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
        Expanded(
          child: Text(title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
          child: Text('$count sertifikat',
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

class _Error extends StatelessWidget {
  final String message;
  const _Error({required this.message});

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
