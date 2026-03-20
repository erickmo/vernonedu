import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/canvas_item_entity.dart';
import '../cubit/canvas_item_cubit.dart';
import '../cubit/canvas_item_state.dart';
import '../widgets/bmc_canvas_widget.dart';
import '../widgets/canvas_sticky_note_widget.dart';
import '../widgets/dt_canvas_widget.dart';
import '../widgets/flywheel_canvas_widget.dart';
import '../widgets/pestel_canvas_widget.dart';
import '../widgets/vpc_canvas_widget.dart';

/// Konfigurasi worksheet per tipe.
class _WorksheetConfig {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<_WorksheetField> fields;

  const _WorksheetConfig({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.fields,
  });
}

class _WorksheetField {
  final String label;
  final String hint;
  final int maxLines;

  const _WorksheetField({
    required this.label,
    required this.hint,
    this.maxLines = 4,
  });
}

/// Worksheet form page — form isian untuk setiap tahapan bisnis ideation.
class WorksheetPage extends StatefulWidget {
  final String businessId;
  final String worksheetKey;

  const WorksheetPage({
    super.key,
    required this.businessId,
    required this.worksheetKey,
  });

  @override
  State<WorksheetPage> createState() => _WorksheetPageState();
}

class _WorksheetPageState extends State<WorksheetPage> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final _WorksheetConfig _config;
  late final ScrollController _scrollController;
  late final Map<String, GlobalKey> _sectionKeys;

  static const _configs = {
    'pestel': _WorksheetConfig(
      title: 'PESTEL Analysis',
      description: 'Analisis faktor eksternal yang mempengaruhi bisnis kamu.',
      icon: Icons.public_rounded,
      color: Color(0xFF4D2975),
      fields: [
        _WorksheetField(
          label: 'Political',
          hint: 'Regulasi pemerintah, kebijakan pajak, stabilitas politik yang mempengaruhi bisnis kamu...',
        ),
        _WorksheetField(
          label: 'Economic',
          hint: 'Kondisi ekonomi, inflasi, daya beli target market, tingkat pengangguran...',
        ),
        _WorksheetField(
          label: 'Social',
          hint: 'Tren sosial, demografi, gaya hidup, budaya, dan preferensi masyarakat...',
        ),
        _WorksheetField(
          label: 'Technological',
          hint: 'Teknologi yang tersedia, inovasi terbaru, adopsi digital di industri...',
        ),
        _WorksheetField(
          label: 'Environmental',
          hint: 'Faktor lingkungan, sustainability, regulasi lingkungan, kesadaran eco-friendly...',
        ),
        _WorksheetField(
          label: 'Legal',
          hint: 'Hukum bisnis, perizinan, regulasi industri, perlindungan konsumen...',
        ),
      ],
    ),
    'design-thinking': _WorksheetConfig(
      title: 'Design Thinking',
      description: 'Framework inovasi untuk memahami masalah dan merancang solusi.',
      icon: Icons.psychology_rounded,
      color: Color(0xFF0168FA),
      fields: [
        _WorksheetField(
          label: 'Empathize',
          hint: 'Siapa target user kamu? Apa masalah dan kebutuhan mereka? Ceritakan hasil observasi dan interview...',
          maxLines: 5,
        ),
        _WorksheetField(
          label: 'Define',
          hint: 'Rumuskan problem statement yang jelas. "[User] membutuhkan [kebutuhan] karena [insight]..."',
        ),
        _WorksheetField(
          label: 'Ideate',
          hint: 'Brainstorm minimal 5 ide solusi kreatif untuk masalah yang sudah didefinisikan...',
          maxLines: 6,
        ),
        _WorksheetField(
          label: 'Prototype',
          hint: 'Deskripsikan rancangan awal solusi kamu. Bisa berupa sketsa, mockup, atau MVP...',
        ),
        _WorksheetField(
          label: 'Test',
          hint: 'Bagaimana rencana validasi solusi kamu? Siapa yang akan menguji? Metrik keberhasilan?',
        ),
      ],
    ),
    'value-proposition': _WorksheetConfig(
      title: 'Value Proposition Canvas',
      description: 'Pemetaan kecocokan antara customer needs dan value yang kamu tawarkan.',
      icon: Icons.diamond_rounded,
      color: Color(0xFF10B759),
      fields: [
        _WorksheetField(
          label: 'Customer Jobs',
          hint: 'Apa yang ingin dicapai customer? Masalah apa yang ingin mereka selesaikan?',
        ),
        _WorksheetField(
          label: 'Customer Pains',
          hint: 'Apa yang menghambat customer? Risiko, frustrasi, dan hal negatif yang mereka alami...',
        ),
        _WorksheetField(
          label: 'Customer Gains',
          hint: 'Apa yang diharapkan customer? Manfaat, keinginan, dan hal positif yang mereka cari...',
        ),
        _WorksheetField(
          label: 'Products & Services',
          hint: 'Produk atau jasa apa yang kamu tawarkan untuk membantu customer?',
        ),
        _WorksheetField(
          label: 'Pain Relievers',
          hint: 'Bagaimana produk/jasa kamu mengurangi pain customer?',
        ),
        _WorksheetField(
          label: 'Gain Creators',
          hint: 'Bagaimana produk/jasa kamu menciptakan gain untuk customer?',
        ),
      ],
    ),
    'business-model-canvas': _WorksheetConfig(
      title: 'Business Model Canvas',
      description: '9 building blocks untuk merancang model bisnis yang sustainable.',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFFF6F00),
      fields: [
        _WorksheetField(
          label: 'Customer Segments',
          hint: 'Siapa customer utama kamu? Segmentasi berdasarkan demografi, perilaku, kebutuhan...',
        ),
        _WorksheetField(
          label: 'Value Propositions',
          hint: 'Apa value unik yang kamu tawarkan? Mengapa customer memilih kamu?',
        ),
        _WorksheetField(
          label: 'Channels',
          hint: 'Bagaimana kamu menjangkau customer? Online, offline, partnership?',
        ),
        _WorksheetField(
          label: 'Customer Relationships',
          hint: 'Bagaimana kamu membangun dan mempertahankan hubungan dengan customer?',
        ),
        _WorksheetField(
          label: 'Revenue Streams',
          hint: 'Dari mana pendapatan bisnis kamu? Model pricing, subscription, freemium?',
        ),
        _WorksheetField(
          label: 'Key Resources',
          hint: 'Apa sumber daya utama yang dibutuhkan? Manusia, teknologi, modal, aset?',
        ),
        _WorksheetField(
          label: 'Key Activities',
          hint: 'Aktivitas utama apa yang harus dilakukan agar bisnis berjalan?',
        ),
        _WorksheetField(
          label: 'Key Partnerships',
          hint: 'Siapa partner strategis kamu? Supplier, distributor, platform?',
        ),
        _WorksheetField(
          label: 'Cost Structure',
          hint: 'Apa saja biaya utama bisnis kamu? Fixed cost, variable cost?',
        ),
      ],
    ),
    'flywheel-marketing': _WorksheetConfig(
      title: 'Flywheel Marketing',
      description: 'Strategi marketing berkelanjutan yang menempatkan customer di pusat.',
      icon: Icons.refresh_rounded,
      color: Color(0xFFDC3545),
      fields: [
        _WorksheetField(
          label: 'Attract',
          hint: 'Bagaimana menarik calon customer? Content marketing, SEO, social media, ads?',
        ),
        _WorksheetField(
          label: 'Engage',
          hint: 'Bagaimana membangun hubungan dengan prospect? Email, demo, consultation, free trial?',
        ),
        _WorksheetField(
          label: 'Delight',
          hint: 'Bagaimana membuat customer puas dan loyal? Customer service, loyalty program, surprise?',
        ),
        _WorksheetField(
          label: 'Friction Points',
          hint: 'Apa yang menghambat flywheel? Bottleneck, proses lambat, poor experience?',
        ),
        _WorksheetField(
          label: 'Force (Accelerators)',
          hint: 'Apa yang mempercepat flywheel? Referral, word-of-mouth, viral loop, automation?',
        ),
      ],
    ),
  };

  String _worksheetKeyToCanvasType(String worksheetKey) {
    switch (worksheetKey) {
      case 'business-model-canvas':
        return 'bmc';
      case 'value-proposition':
        return 'vpc';
      case 'design-thinking':
        return 'design-thinking';
      case 'pestel':
        return 'pestel';
      case 'flywheel-marketing':
        return 'flywheel';
      default:
        return worksheetKey;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _config = _configs[widget.worksheetKey] ?? _configs['pestel']!;
    _controllers = {
      for (final field in _config.fields) field.label: TextEditingController(),
    };

    _sectionKeys = {};
    final sectionIds = _getCanvasSectionIds();
    for (final sectionId in sectionIds) {
      _sectionKeys[sectionId] = GlobalKey();
    }

    // Load items from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final canvasType = _worksheetKeyToCanvasType(widget.worksheetKey);
      context.read<CanvasItemCubit>().loadItems(
            businessId: widget.businessId,
            canvasType: canvasType,
          );
    });
  }

  List<String> _getCanvasSectionIds() {
    switch (widget.worksheetKey) {
      case 'business-model-canvas':
        return [
          'customer-segments',
          'value-propositions',
          'channels',
          'customer-relationships',
          'revenue-streams',
          'key-resources',
          'key-activities',
          'key-partnerships',
          'cost-structure',
        ];
      case 'value-proposition':
        return [
          'customer-jobs',
          'pains',
          'gains',
          'products-services',
          'pain-relievers',
          'gain-creators',
        ];
      case 'design-thinking':
        return ['empathize', 'define', 'ideate', 'prototype', 'test'];
      case 'pestel':
        return [
          'political',
          'economic',
          'social',
          'technological',
          'environmental',
          'legal',
        ];
      case 'flywheel-marketing':
        return [
          'attract',
          'engage',
          'delight',
          'friction-points',
          'force-accelerators',
        ];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  /// Convert CanvasItemEntity to CanvasItem for widgets.
  CanvasItem _entityToCanvasItem(CanvasItemEntity entity) {
    return CanvasItem(
      id: entity.id,
      text: entity.text,
      note: entity.note,
      isExpanded: false,
    );
  }

  Map<String, List<CanvasItem>> _buildSectionItemsFromState(
    CanvasItemState state,
  ) {
    if (state is CanvasItemLoaded) {
      final result = <String, List<CanvasItem>>{};
      for (final sectionId in _getCanvasSectionIds()) {
        final entities = state.itemsBySection[sectionId] ?? [];
        result[sectionId] = entities.map(_entityToCanvasItem).toList();
      }
      return result;
    }
    // Return empty sections if not loaded
    return {
      for (final sectionId in _getCanvasSectionIds()) sectionId: [],
    };
  }

  void _addItem(String sectionId) {
    final canvasType = _worksheetKeyToCanvasType(widget.worksheetKey);
    context.read<CanvasItemCubit>().createItem(
          businessId: widget.businessId,
          canvasType: canvasType,
          sectionId: sectionId,
          text: '',
          note: '',
        );
  }

  void _updateItem(CanvasItem updatedItem) {
    context.read<CanvasItemCubit>().updateItem(
          id: updatedItem.id,
          text: updatedItem.text,
          note: updatedItem.note,
        );
  }

  void _deleteItem(String itemId) {
    context.read<CanvasItemCubit>().deleteItem(id: itemId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CanvasItemCubit, CanvasItemState>(
      listener: (context, state) {
        if (state is CanvasItemError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        final sectionItems = _buildSectionItemsFromState(state);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumb(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildHeader(),
              const SizedBox(height: AppDimensions.spacingL),
              if (state is CanvasItemLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildCanvasContent(context, sectionItems),
              const SizedBox(height: AppDimensions.spacingXL),
              _buildActions(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCanvasContent(
    BuildContext context,
    Map<String, List<CanvasItem>> sectionItems,
  ) {
    switch (widget.worksheetKey) {
      case 'business-model-canvas':
        return BMCCanvasWidget(
          sectionItems: sectionItems,
          onItemUpdate: _updateItem,
          onItemDelete: _deleteItem,
          onAddItem: _addItem,
          scrollController: _scrollController,
          sectionKeys: _sectionKeys,
        );
      case 'value-proposition':
        return VPCCanvasWidget(
          sectionItems: sectionItems,
          onItemUpdate: _updateItem,
          onItemDelete: _deleteItem,
          onAddItem: _addItem,
          scrollController: _scrollController,
          sectionKeys: _sectionKeys,
        );
      case 'design-thinking':
        return DTCanvasWidget(
          sectionItems: sectionItems,
          onItemUpdate: _updateItem,
          onItemDelete: _deleteItem,
          onAddItem: _addItem,
          scrollController: _scrollController,
          sectionKeys: _sectionKeys,
        );
      case 'pestel':
        return PestelCanvasWidget(
          sectionItems: sectionItems,
          onItemUpdate: _updateItem,
          onItemDelete: _deleteItem,
          onAddItem: _addItem,
          scrollController: _scrollController,
          sectionKeys: _sectionKeys,
        );
      case 'flywheel-marketing':
        return FlywheelCanvasWidget(
          sectionItems: sectionItems,
          onItemUpdate: _updateItem,
          onItemDelete: _deleteItem,
          onAddItem: _addItem,
          scrollController: _scrollController,
          sectionKeys: _sectionKeys,
        );
      default:
        return PestelCanvasWidget(
          sectionItems: sectionItems,
          onItemUpdate: _updateItem,
          onItemDelete: _deleteItem,
          onAddItem: _addItem,
          scrollController: _scrollController,
          sectionKeys: _sectionKeys,
        );
    }
  }

  Widget _buildBreadcrumb() {
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
        const _BreadcrumbSeparator(),
        InkWell(
          onTap: () =>
              context.go('/business-ideation/${widget.businessId}'),
          child: Text(
            'Bisnis 001',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const _BreadcrumbSeparator(),
        Text(
          _config.title,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_config.color, _config.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(_config.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _config.title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _config.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft tersimpan')),
              );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
            ),
            child: Text(
              'Simpan Draft',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Worksheet berhasil disimpan!'),
                    backgroundColor: AppColors.success,
                  ),
                );
                context.go('/business-ideation/${widget.businessId}');
              }
            },
            child: Text(
              'Submit',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BreadcrumbSeparator extends StatelessWidget {
  const _BreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.chevron_right_rounded,
          size: 16, color: AppColors.textMuted),
    );
  }
}
