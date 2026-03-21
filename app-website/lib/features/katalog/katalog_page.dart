import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/public_course_model.dart';
import '../../core/router/app_router.dart';
import '../../core/services/public_course_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/footer_widget.dart';
import '../../core/widgets/gradient_button.dart';
import '../../core/widgets/navbar_widget.dart';

// ─── Filter model ─────────────────────────────────────────────────────────────

class _KatalogFilter {
  String search;
  List<String> types;
  String? departmentId;
  int minPrice;
  int maxPrice;
  String? scheduleAvailability;
  String sortBy;

  _KatalogFilter({
    this.search = '',
    List<String>? types,
    this.departmentId,
    this.minPrice = 0,
    this.maxPrice = 20000000,
    this.scheduleAvailability,
    this.sortBy = 'popular',
  }) : types = types ?? [];

  _KatalogFilter copyWith({
    String? search,
    List<String>? types,
    Object? departmentId = _sentinel,
    int? minPrice,
    int? maxPrice,
    Object? scheduleAvailability = _sentinel,
    String? sortBy,
  }) {
    return _KatalogFilter(
      search: search ?? this.search,
      types: types ?? this.types,
      departmentId:
          departmentId == _sentinel ? this.departmentId : departmentId as String?,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      scheduleAvailability: scheduleAvailability == _sentinel
          ? this.scheduleAvailability
          : scheduleAvailability as String?,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  static const _sentinel = Object();
}

// ─── KatalogPage ──────────────────────────────────────────────────────────────

/// Course catalog page — /katalog
class KatalogPage extends StatefulWidget {
  const KatalogPage({super.key});

  @override
  State<KatalogPage> createState() => _KatalogPageState();
}

class _KatalogPageState extends State<KatalogPage> {
  final _service = PublicCourseService();
  List<PublicCourse> _courses = [];
  List<PublicDepartment> _departments = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalCourses = 0;
  _KatalogFilter _filter = _KatalogFilter();

  static const _pageSize = 12;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadCourses(reset: true);
  }

  Future<void> _loadDepartments() async {
    final depts = await _service.fetchDepartments();
    if (mounted) setState(() => _departments = depts);
  }

  Future<void> _loadCourses({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _currentPage = 0;
      });
    } else {
      setState(() { _loading = true; _error = null; });
    }

    try {
      final result = await _service.fetchCoursesFiltered(
        search: _filter.search.isEmpty ? null : _filter.search,
        types: _filter.types.isEmpty ? null : _filter.types,
        departmentId: _filter.departmentId,
        minPrice: _filter.minPrice > 0 ? _filter.minPrice : null,
        maxPrice: _filter.maxPrice < 20000000 ? _filter.maxPrice : null,
        scheduleAvailability: _filter.scheduleAvailability,
        sortBy: _filter.sortBy,
        offset: _currentPage * _pageSize,
        limit: _pageSize,
      );
      if (mounted) {
        setState(() {
          _courses = result.data;
          _totalCourses = result.total;
          _totalPages = (result.total / _pageSize).ceil().clamp(1, 999);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Gagal memuat katalog.'; _loading = false; });
      }
    }
  }

  void _applyFilter(_KatalogFilter f) {
    setState(() => _filter = f);
    _loadCourses(reset: true);
  }

  void _goPage(int page) {
    setState(() => _currentPage = page);
    _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    return WebScaffold(
      body: Column(
        children: [
          _KatalogHero(),
          Container(
            width: double.infinity,
            color: AppColors.bgPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile
                  ? AppDimensions.s24
                  : Responsive.sectionPaddingH(context),
              vertical: AppDimensions.s48,
            ),
            child: isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(),
          ),
          const FooterWidget(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterSidebar(
          filter: _filter,
          departments: _departments,
          onApply: _applyFilter,
        ),
        const SizedBox(width: AppDimensions.s32),
        Expanded(
          child: Column(
            children: [
              _buildResultInfo(),
              const SizedBox(height: AppDimensions.s24),
              _CourseGrid(
                courses: _courses,
                loading: _loading,
                error: _error,
                onRetry: () => _loadCourses(reset: true),
                onCourseTap: (c) => context.go('${AppRouter.katalog}/${c.id}'),
              ),
              if (!_loading && _error == null && _courses.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.s40),
                _Pagination(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPageTap: _goPage,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileFilterButton(),
        const SizedBox(height: AppDimensions.s16),
        _buildResultInfo(),
        const SizedBox(height: AppDimensions.s16),
        _CourseGrid(
          courses: _courses,
          loading: _loading,
          error: _error,
          onRetry: () => _loadCourses(reset: true),
          onCourseTap: (c) => context.go('${AppRouter.katalog}/${c.id}'),
        ),
        if (!_loading && _error == null && _courses.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.s32),
          _Pagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            onPageTap: _goPage,
          ),
        ],
      ],
    );
  }

  Widget _buildMobileFilterButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showMobileFilterSheet,
        icon: const Icon(Icons.tune_rounded),
        label: const Text('Filter & Urutkan'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPurple,
          side: const BorderSide(color: AppColors.brandPurple),
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.s16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.r12),
          ),
        ),
      ),
    );
  }

  Widget _buildResultInfo() {
    if (_loading) return const SizedBox.shrink();
    return Row(
      children: [
        Text(
          '$_totalCourses kursus ditemukan',
          style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  void _showMobileFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.r24),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollCtrl,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: AppDimensions.s12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimensions.r999),
                  ),
                ),
                _FilterSidebar(
                  filter: _filter,
                  departments: _departments,
                  onApply: (f) {
                    Navigator.of(context).pop();
                    _applyFilter(f);
                  },
                  isSheet: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Katalog Hero ─────────────────────────────────────────────────────────────

class _KatalogHero extends StatelessWidget {
  const _KatalogHero();

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
            'Katalog Kursus',
            style: isMobile ? AppTextStyles.displayM : AppTextStyles.displayL,
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0),
          const SizedBox(height: AppDimensions.s16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Temukan program yang tepat untuk karir dan tujuan hidupmu. Filter berdasarkan tipe, harga, dan jadwal.',
              style: AppTextStyles.bodyL,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Sidebar ───────────────────────────────────────────────────────────

class _FilterSidebar extends StatefulWidget {
  final _KatalogFilter filter;
  final List<PublicDepartment> departments;
  final void Function(_KatalogFilter) onApply;
  final bool isSheet;

  const _FilterSidebar({
    required this.filter,
    required this.departments,
    required this.onApply,
    this.isSheet = false,
  });

  @override
  State<_FilterSidebar> createState() => _FilterSidebarState();
}

class _FilterSidebarState extends State<_FilterSidebar> {
  late TextEditingController _searchCtrl;
  late List<String> _selectedTypes;
  String? _selectedDeptId;
  late RangeValues _priceRange;
  String? _scheduleAvailability;
  late String _sortBy;

  static const _allTypes = [
    (label: 'Program Karir', value: 'karir'),
    (label: 'Reguler', value: 'reguler'),
    (label: 'Privat', value: 'privat'),
    (label: 'Sertifikasi', value: 'sertifikasi'),
    (label: 'Kolaborasi', value: 'kolaborasi'),
    (label: 'Inhouse', value: 'inhouse'),
  ];

  static const _sortOptions = [
    (label: 'Terpopuler', value: 'popular'),
    (label: 'Terbaru', value: 'newest'),
    (label: 'Harga Terendah', value: 'price_asc'),
    (label: 'Harga Tertinggi', value: 'price_desc'),
  ];

  @override
  void initState() {
    super.initState();
    _syncFromFilter(widget.filter);
  }

  void _syncFromFilter(_KatalogFilter f) {
    _searchCtrl = TextEditingController(text: f.search);
    _selectedTypes = List.from(f.types);
    _selectedDeptId = f.departmentId;
    _priceRange = RangeValues(
      f.minPrice.toDouble(),
      f.maxPrice.toDouble(),
    );
    _scheduleAvailability = f.scheduleAvailability;
    _sortBy = f.sortBy;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _searchCtrl.text = '';
      _selectedTypes = [];
      _selectedDeptId = null;
      _priceRange = const RangeValues(0, 20000000);
      _scheduleAvailability = null;
      _sortBy = 'popular';
    });
  }

  void _apply() {
    final f = _KatalogFilter(
      search: _searchCtrl.text.trim(),
      types: List.from(_selectedTypes),
      departmentId: _selectedDeptId,
      minPrice: _priceRange.start.toInt(),
      maxPrice: _priceRange.end.toInt(),
      scheduleAvailability: _scheduleAvailability,
      sortBy: _sortBy,
    );
    widget.onApply(f);
  }

  String _fmtPrice(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(0)} jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)} rb';
    return 'Rp 0';
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isSheet) ...[
          Text('Filter', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.s16),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppDimensions.s16),
        ] else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.s24, AppDimensions.s16, AppDimensions.s24, 0,
            ),
            child: Text('Filter & Urutkan', style: AppTextStyles.h3),
          ),
          const SizedBox(height: AppDimensions.s16),
          const Divider(color: AppColors.border),
          const SizedBox(height: AppDimensions.s16),
        ],

        // Search
        _FilterSection(
          title: 'Cari Kursus',
          child: TextField(
            controller: _searchCtrl,
            style: AppTextStyles.bodyS,
            decoration: InputDecoration(
              hintText: 'Cari kursus...',
              hintStyle: AppTextStyles.bodyS.copyWith(
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: AppDimensions.iconS,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.bgInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.r8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.r8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.r8),
                borderSide: const BorderSide(color: AppColors.brandPurple),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.s16,
                vertical: AppDimensions.s12,
              ),
            ),
          ),
        ),

        // Tipe Program
        _FilterSection(
          title: 'Tipe Program',
          child: Column(
            children: _allTypes.map((t) {
              final selected = _selectedTypes.contains(t.value);
              return _CompactCheckbox(
                label: t.label,
                value: selected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedTypes.add(t.value);
                    } else {
                      _selectedTypes.remove(t.value);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),

        // Departemen
        if (widget.departments.isNotEmpty)
          _FilterSection(
            title: 'Departemen',
            child: _CompactDropdown<String?>(
              value: _selectedDeptId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Semua Departemen'),
                ),
                ...widget.departments.map(
                  (d) => DropdownMenuItem<String?>(
                    value: d.id,
                    child: Text(d.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedDeptId = v),
            ),
          ),

        // Harga
        _FilterSection(
          title: 'Rentang Harga',
          child: Column(
            children: [
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 20000000,
                divisions: 40,
                activeColor: AppColors.brandPurple,
                inactiveColor: AppColors.border,
                onChanged: (v) => setState(() => _priceRange = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmtPrice(_priceRange.start),
                      style: AppTextStyles.bodyXS),
                  Text(_fmtPrice(_priceRange.end),
                      style: AppTextStyles.bodyXS),
                ],
              ),
            ],
          ),
        ),

        // Jadwal
        _FilterSection(
          title: 'Jadwal',
          child: Column(
            children: [
              _CompactRadio<String?>(
                label: 'Semua',
                value: null,
                groupValue: _scheduleAvailability,
                onChanged: (v) => setState(() => _scheduleAvailability = v),
              ),
              _CompactRadio<String?>(
                label: 'Tersedia Sekarang',
                value: 'now',
                groupValue: _scheduleAvailability,
                onChanged: (v) => setState(() => _scheduleAvailability = v),
              ),
              _CompactRadio<String?>(
                label: 'Akan Datang',
                value: 'upcoming',
                groupValue: _scheduleAvailability,
                onChanged: (v) => setState(() => _scheduleAvailability = v),
              ),
            ],
          ),
        ),

        // Urutkan
        _FilterSection(
          title: 'Urutkan',
          child: _CompactDropdown<String>(
            value: _sortBy,
            items: _sortOptions
                .map(
                  (s) => DropdownMenuItem<String>(
                    value: s.value,
                    child: Text(s.label),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _sortBy = v ?? 'popular'),
          ),
        ),

        const SizedBox(height: AppDimensions.s24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.s12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.r8),
                  ),
                ),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: AppDimensions.s12),
            Expanded(
              flex: 2,
              child: GradientButton(
                label: 'Terapkan',
                onTap: _apply,
                height: AppDimensions.btnHeightM,
                horizontalPadding: AppDimensions.s16,
                borderRadius: AppDimensions.r8,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.s24),
      ],
    );

    if (widget.isSheet) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s24),
        child: content,
      );
    }

    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.s20),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppDimensions.r16),
          border: Border.all(color: AppColors.border),
        ),
        child: content,
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelM),
          const SizedBox(height: AppDimensions.s8),
          child,
        ],
      ),
    );
  }
}

class _CompactCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool?) onChanged;

  const _CompactCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label, style: AppTextStyles.bodyS),
        dense: true,
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.brandPurple,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class _CompactRadio<T> extends StatelessWidget {
  final String label;
  final T value;
  final T? groupValue;
  final void Function(T?) onChanged;

  const _CompactRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Row(
            children: [
              Radio<T>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: AppColors.brandPurple,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Text(label, style: AppTextStyles.bodyS),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(AppDimensions.r8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: AppTextStyles.bodyS,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: AppDimensions.iconS,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Course Grid ──────────────────────────────────────────────────────────────

class _CourseGrid extends StatelessWidget {
  final List<PublicCourse> courses;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final void Function(PublicCourse) onCourseTap;

  const _CourseGrid({
    required this.courses,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.s96),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.s64),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
              const SizedBox(height: AppDimensions.s16),
              Text(error!, style: AppTextStyles.bodyL),
              const SizedBox(height: AppDimensions.s24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.s64),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppDimensions.s16),
              Text(
                'Tidak ada kursus yang sesuai filter.',
                style: AppTextStyles.bodyL,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final crossCount = Responsive.isMobile(context)
        ? 1
        : Responsive.isTablet(context)
            ? 2
            : 3;
    final screenW = MediaQuery.of(context).size.width;
    final hPad = Responsive.sectionPaddingH(context);
    final sidebarW = Responsive.isDesktop(context) ? 260.0 + AppDimensions.s32 : 0.0;
    final availW = screenW - hPad * 2 - sidebarW;
    final cardW = crossCount == 1
        ? double.infinity
        : (availW - AppDimensions.s24 * (crossCount - 1)) / crossCount;

    return Wrap(
      spacing: AppDimensions.s24,
      runSpacing: AppDimensions.s24,
      children: courses.asMap().entries.map((e) {
        return SizedBox(
          width: cardW,
          child: _CourseCard(
            course: e.value,
            index: e.key,
            onTap: () => onCourseTap(e.value),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Course Card ──────────────────────────────────────────────────────────────

class _CourseCard extends StatefulWidget {
  final PublicCourse course;
  final int index;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _hovered = false;

  String _formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.r16),
            border: Border.all(
              color: _hovered ? AppColors.brandPurple : AppColors.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.brandPurple.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.r16),
                    topRight: Radius.circular(AppDimensions.r16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.school_outlined,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    if (c.courseType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.s8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(AppDimensions.r4),
                        ),
                        child: Text(
                          c.courseType!.name,
                          style: AppTextStyles.labelS,
                        ),
                      ),
                    const SizedBox(height: AppDimensions.s12),
                    Text(
                      c.name,
                      style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.s8),
                    Text(
                      c.description,
                      style: AppTextStyles.bodyS,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.s16),

                    // Stats row
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${c.batchCount} batch',
                          style: AppTextStyles.bodyXS,
                        ),
                        const SizedBox(width: AppDimensions.s12),
                        const Icon(
                          Icons.group_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${c.studentCount} siswa',
                          style: AppTextStyles.bodyXS,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.s12),

                    // Price + CTA row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          c.priceFrom > 0
                              ? 'Mulai ${_formatPrice(c.priceFrom)}'
                              : 'Cek Harga',
                          style: AppTextStyles.labelM.copyWith(
                            color: AppColors.brandPurple,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onTap,
                          child: Text(
                            'Lihat Detail →',
                            style: AppTextStyles.labelS.copyWith(
                              color: AppColors.brandPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (widget.index * 60).ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

// ─── Pagination ───────────────────────────────────────────────────────────────

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final void Function(int) onPageTap;

  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageTap,
  });

  List<int?> _buildPageItems() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i);
    }
    final items = <int?>[];
    if (currentPage <= 3) {
      items.addAll([0, 1, 2, 3, 4]);
      items.add(null); // ellipsis
      items.add(totalPages - 1);
    } else if (currentPage >= totalPages - 4) {
      items.add(0);
      items.add(null);
      for (var i = totalPages - 5; i < totalPages; i++) { items.add(i); }
    } else {
      items.add(0);
      items.add(null);
      items.addAll([currentPage - 1, currentPage, currentPage + 1]);
      items.add(null);
      items.add(totalPages - 1);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final pages = _buildPageItems();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Prev
        _PageBtn(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 0,
          onTap: () => onPageTap(currentPage - 1),
        ),
        const SizedBox(width: AppDimensions.s8),
        ...pages.map((p) {
          if (p == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.s4,
              ),
              child: Text('...', style: AppTextStyles.bodyS),
            );
          }
          final isSelected = p == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _PageNumBtn(
              page: p,
              selected: isSelected,
              onTap: () => onPageTap(p),
            ),
          );
        }),
        const SizedBox(width: AppDimensions.s8),
        // Next
        _PageBtn(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages - 1,
          onTap: () => onPageTap(currentPage + 1),
        ),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.r8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconS,
            color: enabled ? AppColors.textSecondary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _PageNumBtn extends StatelessWidget {
  final int page;
  final bool selected;
  final VoidCallback onTap;

  const _PageNumBtn({required this.page, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppDimensions.r8),
            border: Border.all(
              color: selected ? AppColors.brandPurple : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              '${page + 1}',
              style: AppTextStyles.labelS.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
