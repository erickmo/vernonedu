import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class ReportNavigationPage extends StatelessWidget {
  const ReportNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan Keuangan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            'Laporan Standar Akuntansi',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.xl),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppDimensions.md,
              mainAxisSpacing: AppDimensions.md,
              childAspectRatio: 2.8,
              shrinkWrap: true,
              children: const [
                _ReportCard(
                  icon: Icons.balance_outlined,
                  title: 'Neraca',
                  description: 'Laporan posisi keuangan perusahaan — aset, kewajiban, dan ekuitas',
                  route: '/finance/reports/balance-sheet',
                  color: AppColors.primary,
                ),
                _ReportCard(
                  icon: Icons.bar_chart_outlined,
                  title: 'Laba Rugi',
                  description: 'Pendapatan, beban, dan laba bersih dalam satu periode',
                  route: '/finance/reports/profit-loss',
                  color: AppColors.secondary,
                ),
                _ReportCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Arus Kas',
                  description: 'Aliran kas masuk dan keluar dari aktivitas operasi, investasi, dan pendanaan',
                  route: '/finance/reports/cash-flow',
                  color: AppColors.info,
                ),
                _ReportCard(
                  icon: Icons.book_outlined,
                  title: 'Buku Besar',
                  description: 'Catatan detail transaksi per akun dengan running balance',
                  route: '/finance/reports/ledger',
                  color: AppColors.warning,
                ),
                _ReportCard(
                  icon: Icons.calculate_outlined,
                  title: 'Neraca Saldo',
                  description: 'Daftar semua akun dengan saldo debit dan kredit untuk validasi keseimbangan',
                  route: '/finance/reports/trial-balance',
                  color: AppColors.roleDirector,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String route;
  final Color color;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.color,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.06) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: _hovered ? widget.color : AppColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Icon(widget.icon, color: widget.color, size: AppDimensions.iconLg),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _hovered ? widget.color : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _hovered ? widget.color : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
