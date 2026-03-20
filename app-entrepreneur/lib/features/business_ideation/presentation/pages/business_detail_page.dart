import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../cubit/business_cubit.dart';
import '../cubit/business_state.dart';
import '../widgets/worksheet_card_widget.dart';

/// Detail page untuk satu bisnis — menampilkan 5 tahapan worksheet.
class BusinessDetailPage extends StatefulWidget {
  final String businessId;

  const BusinessDetailPage({super.key, required this.businessId});

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusinessCubit>().getBusinessById(id: widget.businessId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BusinessCubit, BusinessState>(
      builder: (context, state) {
        final businessName = state is BusinessDetailLoaded
            ? state.business.name
            : '...';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumb(context, businessName),
              const SizedBox(height: AppDimensions.spacingL),
              if (state is BusinessLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _buildHeader(businessName),
                const SizedBox(height: AppDimensions.spacingL),
                _buildWorksheetTimeline(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumb(BuildContext context, String businessName) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go('/business-ideation'),
          child: Text(
            'Business Ideation',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          businessName,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String name, {String? subtitle}) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: const Icon(Icons.business_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Selesaikan semua worksheet untuk melanjutkan ke Business Launchpad',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorksheetTimeline(BuildContext context) {
    const worksheets = [
      WorksheetInfo(
        key: 'pestel',
        title: 'PESTEL Analysis',
        description:
            'Analisis faktor eksternal yang mempengaruhi bisnis: Political, Economic, Social, Technological, Environmental, Legal.',
        icon: Icons.public_rounded,
        color: Color(0xFF4D2975),
        status: WorksheetStatus.completed,
        fields: [
          'Political — Regulasi & kebijakan pemerintah',
          'Economic — Kondisi ekonomi & daya beli',
          'Social — Tren sosial & demografi',
          'Technological — Teknologi yang tersedia',
          'Environmental — Faktor lingkungan',
          'Legal — Hukum & regulasi industri',
        ],
      ),
      WorksheetInfo(
        key: 'design-thinking',
        title: 'Design Thinking',
        description:
            'Framework inovasi untuk memahami masalah user dan merancang solusi.',
        icon: Icons.psychology_rounded,
        color: Color(0xFF0168FA),
        status: WorksheetStatus.inProgress,
        fields: [
          'Empathize — Siapa user kamu? Apa masalah mereka?',
          'Define — Rumuskan problem statement',
          'Ideate — Brainstorm solusi kreatif',
          'Prototype — Rancangan awal solusi',
          'Test — Validasi dengan user nyata',
        ],
      ),
      WorksheetInfo(
        key: 'value-proposition',
        title: 'Value Proposition Canvas',
        description:
            'Pemetaan kecocokan antara apa yang customer butuhkan dan value yang kamu tawarkan.',
        icon: Icons.diamond_rounded,
        color: Color(0xFF10B759),
        status: WorksheetStatus.notStarted,
        fields: [
          'Customer Jobs — Apa yang ingin dicapai customer?',
          'Pains — Apa yang menghambat customer?',
          'Gains — Apa yang diharapkan customer?',
          'Products & Services — Apa yang kamu tawarkan?',
          'Pain Relievers — Bagaimana mengurangi pain?',
          'Gain Creators — Bagaimana menciptakan gain?',
        ],
      ),
      WorksheetInfo(
        key: 'business-model-canvas',
        title: 'Business Model Canvas',
        description:
            '9 building blocks untuk merancang model bisnis yang sustainable.',
        icon: Icons.grid_view_rounded,
        color: Color(0xFFFF6F00),
        status: WorksheetStatus.notStarted,
        fields: [
          'Customer Segments',
          'Value Propositions',
          'Channels',
          'Customer Relationships',
          'Revenue Streams',
          'Key Resources',
          'Key Activities',
          'Key Partnerships',
          'Cost Structure',
        ],
      ),
      WorksheetInfo(
        key: 'flywheel-marketing',
        title: 'Flywheel Marketing',
        description:
            'Strategi marketing berkelanjutan yang menempatkan customer di pusat.',
        icon: Icons.refresh_rounded,
        color: Color(0xFFDC3545),
        status: WorksheetStatus.notStarted,
        fields: [
          'Attract — Bagaimana menarik calon customer?',
          'Engage — Bagaimana membangun hubungan?',
          'Delight — Bagaimana membuat customer puas & loyal?',
          'Friction Points — Apa yang menghambat flywheel?',
          'Force — Apa yang mempercepat flywheel?',
        ],
      ),
    ];

    return Column(
      children: worksheets.asMap().entries.map((entry) {
        final index = entry.key;
        final ws = entry.value;
        return WorksheetCardWidget(
          worksheet: ws,
          stepNumber: index + 1,
          isLast: index == worksheets.length - 1,
          onOpen: () {
            context.go(
              '/business-ideation/${widget.businessId}/worksheet/${ws.key}',
            );
          },
        );
      }).toList(),
    );
  }
}
