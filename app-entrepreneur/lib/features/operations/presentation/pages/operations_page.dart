import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'purchasing_tab.dart';
import 'sales_tab.dart';
import 'stock_tab.dart';
import 'finance_tab.dart';

/// Operations page — tab-based layout.
class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: 'Pembelian'),
    Tab(text: 'Penjualan'),
    Tab(text: 'Stock'),
    Tab(text: 'Finance'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.spacingL,
            AppDimensions.spacingL,
            AppDimensions.spacingL,
            0,
          ),
          child: _buildHeader(),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              PurchasingTab(),
              SalesTab(),
              StockTab(),
              FinanceTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operations',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          'Kelola operasional bisnis: pembelian, penjualan, stock, dan keuangan.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: _tabs,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding:
            const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      ),
    );
  }
}
