import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/utils/date_format_util.dart';
import '../../../domain/entities/referral_entity.dart';
import '../../../domain/entities/referral_partner_entity.dart';
import '../../cubit/marketing_cubit.dart';
import '../../cubit/marketing_state.dart';

class MarketingReferralTab extends StatefulWidget {
  const MarketingReferralTab({super.key});

  @override
  State<MarketingReferralTab> createState() => _MarketingReferralTabState();
}

class _MarketingReferralTabState extends State<MarketingReferralTab> {
  String? _expandedPartnerId;
  List<ReferralEntity> _referrals = [];

  final _currFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  void _showPartnerForm(BuildContext context,
      {ReferralPartnerEntity? partner}) {
    final nameCtrl = TextEditingController(text: partner?.name ?? '');
    final emailCtrl =
        TextEditingController(text: partner?.contactEmail ?? '');
    final codeCtrl =
        TextEditingController(text: partner?.referralCode ?? '');
    final commValueCtrl = TextEditingController(
        text: partner?.commissionValue.toString() ?? '');
    String commType = partner?.commissionType ?? 'percentage';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(partner == null
              ? 'Tambah Referral Partner'
              : 'Edit Referral Partner'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama *'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Kontak'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: codeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Kode Referral'),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  DropdownButtonFormField<String>(
                    value: commType,
                    decoration:
                        const InputDecoration(labelText: 'Tipe Komisi'),
                    items: const [
                      DropdownMenuItem(
                          value: 'percentage', child: Text('Persentase (%)')),
                      DropdownMenuItem(
                          value: 'fixed', child: Text('Nominal Tetap (Rp)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setSt(() => commType = v);
                    },
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  TextField(
                    controller: commValueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: commType == 'percentage'
                          ? 'Nilai Komisi (%)'
                          : 'Nilai Komisi (Rp)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final data = {
                  'name': nameCtrl.text.trim(),
                  'contact_email': emailCtrl.text.trim(),
                  'referral_code': codeCtrl.text.trim(),
                  'commission_type': commType,
                  'commission_value':
                      double.tryParse(commValueCtrl.text.trim()) ?? 0.0,
                };
                final cubit = context.read<MarketingCubit>();
                if (partner == null) {
                  cubit.createReferralPartner(data);
                } else {
                  cubit.updateReferralPartner(partner.id, data);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleExpand(
      BuildContext context, String partnerId) async {
    if (_expandedPartnerId == partnerId) {
      setState(() {
        _expandedPartnerId = null;
        _referrals = [];
      });
      return;
    }
    setState(() => _expandedPartnerId = partnerId);
    final cubit = context.read<MarketingCubit>();
    await cubit.loadReferrals(partnerId);
    if (!mounted) return;
    final st = cubit.state;
    if (st is MarketingReferralsLoaded && st.partnerId == partnerId) {
      setState(() => _referrals = st.referrals);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketingCubit, MarketingState>(
      builder: (context, state) {
        final partners = state is MarketingLoaded
            ? state.referralPartners
            : <ReferralPartnerEntity>[];

        final totalComm = partners.fold(
            0.0, (sum, p) => sum + p.totalCommission);
        final totalReferrals =
            partners.fold(0, (sum, p) => sum + p.totalReferrals);
        final totalEnrolled =
            partners.fold(0, (sum, p) => sum + p.totalEnrolled);
        final convPct = totalReferrals > 0
            ? (totalEnrolled / totalReferrals * 100).toStringAsFixed(1)
            : '0.0';
        final activeCount = partners.where((p) => p.isActive).length;

        return Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat cards
              Row(
                children: [
                  _buildStatCard('Partner Aktif', activeCount.toString(),
                      Icons.group_outlined, AppColors.primary),
                  const SizedBox(width: AppDimensions.md),
                  _buildStatCard('Total Referral', totalReferrals.toString(),
                      Icons.share_outlined, AppColors.info),
                  const SizedBox(width: AppDimensions.md),
                  _buildStatCard('Total Komisi',
                      _currFmt.format(totalComm),
                      Icons.payments_outlined, AppColors.success),
                  const SizedBox(width: AppDimensions.md),
                  _buildStatCard('Konversi %', '$convPct%',
                      Icons.trending_up_outlined, AppColors.warning),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              // Add button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () => _showPartnerForm(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah Referral Partner'),
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              // Table
              Expanded(
                child: partners.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_outlined,
                                size: 48, color: AppColors.textHint),
                            SizedBox(height: AppDimensions.sm),
                            Text('Belum ada data',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: partners.length,
                        itemBuilder: (context, index) {
                          final partner = partners[index];
                          final isExpanded =
                              _expandedPartnerId == partner.id;
                          return Card(
                            margin: const EdgeInsets.only(
                                bottom: AppDimensions.sm),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd),
                              side: const BorderSide(
                                  color: AppColors.border),
                            ),
                            elevation: 0,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: partner.isActive
                                        ? AppColors.primarySurface
                                        : AppColors.surfaceVariant,
                                    child: Text(
                                      partner.name.isNotEmpty
                                          ? partner.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                          color: partner.isActive
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(partner.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (partner.isActive
                                                  ? AppColors.success
                                                  : AppColors.textSecondary)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          partner.isActive ? 'Aktif' : 'Nonaktif',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: partner.isActive
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Kode: ${partner.referralCode} · ${partner.commissionDisplay} · ${partner.totalReferrals} referral · ${partner.totalEnrolled} enrolled',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _currFmt
                                            .format(partner.totalCommission),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.success),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 16),
                                        onPressed: () => _showPartnerForm(
                                            context,
                                            partner: partner),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _toggleExpand(context, partner.id),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isExpanded) _buildReferralList(context),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReferralList(BuildContext context) {
    if (_referrals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.md),
        child: Center(
          child: Text('Belum ada referral',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppDimensions.md, 0, AppDimensions.md, AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: DataTable2(
        columnSpacing: 12,
        dataRowHeight: 40,
        headingRowHeight: 36,
        headingRowColor:
            WidgetStateProperty.all(AppColors.primarySurface),
        columns: const [
          DataColumn2(label: Text('ID'), size: ColumnSize.S),
          DataColumn2(label: Text('Status')),
          DataColumn2(label: Text('Komisi')),
          DataColumn2(label: Text('Tanggal')),
        ],
        rows: _referrals.map((r) {
          final color = switch (r.status) {
            'pending' => AppColors.warning,
            'enrolled' => AppColors.info,
            _ => AppColors.success,
          };
          return DataRow2(cells: [
            DataCell(Text(r.id.length > 8 ? r.id.substring(0, 8) : r.id,
                style: const TextStyle(fontSize: 11))),
            DataCell(Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(r.statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            )),
            DataCell(Text(_currFmt.format(r.commission),
                style: const TextStyle(fontSize: 11))),
            DataCell(Text(DateFormatUtil.toDisplay(r.createdAt),
                style: const TextStyle(fontSize: 11))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
