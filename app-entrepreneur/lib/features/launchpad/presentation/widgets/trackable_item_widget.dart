import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

// ─── DATA MODELS ──────────────────────────────────────────────

enum ItemStatus { notStarted, inProgress, completed }

class TrackableItem {
  String name;
  String description;
  ItemStatus status;
  List<LogEntry> logs;
  List<TodoItem> todos;

  TrackableItem({
    required this.name,
    this.description = '',
    this.status = ItemStatus.notStarted,
    List<LogEntry>? logs,
    List<TodoItem>? todos,
  })  : logs = logs ?? [],
        todos = todos ?? [];

  int get completedTodos => todos.where((t) => t.isDone).length;

  double get todoProgress =>
      todos.isEmpty ? 0.0 : completedTodos / todos.length;
}

class LogEntry {
  final String message;
  final DateTime timestamp;

  LogEntry({required this.message, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class TodoItem {
  String text;
  bool isDone;

  TodoItem({required this.text, this.isDone = false});
}

// ─── TRACKABLE LIST WIDGET ────────────────────────────────────

/// Widget untuk mengelola list items yang bisa di-track.
/// Digunakan di Key Partners, Key Activities, Key Resources.
class TrackableListWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String itemLabel;
  final String addButtonLabel;
  final List<String> defaultTodos;

  const TrackableListWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.itemLabel,
    required this.addButtonLabel,
    required this.defaultTodos,
  });

  @override
  State<TrackableListWidget> createState() => _TrackableListWidgetState();
}

class _TrackableListWidgetState extends State<TrackableListWidget> {
  // TODO: replace with Cubit state
  final List<TrackableItem> _items = [];
  int? _expandedIndex;

  void _addItem() {
    final number = (_items.length + 1).toString().padLeft(2, '0');
    setState(() {
      _items.add(
        TrackableItem(
          name: '${widget.itemLabel} $number',
          todos: widget.defaultTodos
              .map((t) => TodoItem(text: t))
              .toList(),
        ),
      );
      _expandedIndex = _items.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryBar(),
        const SizedBox(height: AppDimensions.spacingM),
        ..._items.asMap().entries.map((entry) {
          return _TrackableItemCard(
            item: entry.value,
            index: entry.key,
            color: widget.color,
            isExpanded: _expandedIndex == entry.key,
            onToggleExpand: () {
              setState(() {
                _expandedIndex =
                    _expandedIndex == entry.key ? null : entry.key;
              });
            },
            onUpdate: () => setState(() {}),
            onDelete: () {
              setState(() {
                _items.removeAt(entry.key);
                _expandedIndex = null;
              });
            },
          );
        }),
        const SizedBox(height: AppDimensions.spacingM),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildSummaryBar() {
    final total = _items.length;
    final completed =
        _items.where((i) => i.status == ItemStatus.completed).length;
    final inProgress =
        _items.where((i) => i.status == ItemStatus.inProgress).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildMiniStat('Total', '$total', AppColors.textPrimary),
          const SizedBox(width: AppDimensions.spacingM),
          _buildMiniStat('Progress', '$inProgress', AppColors.info),
          const SizedBox(width: AppDimensions.spacingM),
          _buildMiniStat('Done', '$completed', AppColors.success),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addItem,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(
          widget.addButtonLabel,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.color,
          side: BorderSide(
            color: widget.color.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      ),
    );
  }
}

// ─── SINGLE ITEM CARD ─────────────────────────────────────────

class _TrackableItemCard extends StatelessWidget {
  final TrackableItem item;
  final int index;
  final Color color;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _TrackableItemCard({
    required this.item,
    required this.index,
    required this.color,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isExpanded
              ? color.withValues(alpha: 0.4)
              : AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.divider),
            _TrackableItemDetail(
              item: item,
              color: color,
              onUpdate: onUpdate,
              onDelete: onDelete,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: onToggleExpand,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Row(
          children: [
            _buildStatusDot(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            if (item.todos.isNotEmpty)
              Text(
                '${item.completedTodos}/${item.todos.length}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            const SizedBox(width: AppDimensions.spacingS),
            _buildStatusBadge(),
            const SizedBox(width: AppDimensions.spacingS),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot() {
    final Color dotColor;
    switch (item.status) {
      case ItemStatus.completed:
        dotColor = AppColors.success;
      case ItemStatus.inProgress:
        dotColor = AppColors.info;
      case ItemStatus.notStarted:
        dotColor = AppColors.textMuted;
    }

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final String label;
    final Color badgeColor;

    switch (item.status) {
      case ItemStatus.completed:
        label = 'Done';
        badgeColor = AppColors.success;
      case ItemStatus.inProgress:
        label = 'Progress';
        badgeColor = AppColors.info;
      case ItemStatus.notStarted:
        label = 'Pending';
        badgeColor = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }
}

// ─── ITEM DETAIL (EXPANDED) ───────────────────────────────────

class _TrackableItemDetail extends StatefulWidget {
  final TrackableItem item;
  final Color color;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _TrackableItemDetail({
    required this.item,
    required this.color,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_TrackableItemDetail> createState() => _TrackableItemDetailState();
}

class _TrackableItemDetailState extends State<_TrackableItemDetail> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _logController;
  late final TextEditingController _todoController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descController = TextEditingController(text: widget.item.description);
    _logController = TextEditingController();
    _todoController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _logController.dispose();
    _todoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= AppDimensions.breakpointTablet;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(),
          const SizedBox(height: AppDimensions.spacingM),
          _buildStatusSelector(),
          const SizedBox(height: AppDimensions.spacingL),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTodoSection()),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(child: _buildLogSection()),
              ],
            )
          else ...[
            _buildTodoSection(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildLogSection(),
          ],
          const SizedBox(height: AppDimensions.spacingM),
          _buildDeleteButton(),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          onChanged: (v) {
            widget.item.name = v;
            widget.onUpdate();
          },
          style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: 'Nama',
            labelStyle: GoogleFonts.inter(fontSize: 12),
            isDense: true,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextField(
          controller: _descController,
          onChanged: (v) {
            widget.item.description = v;
            widget.onUpdate();
          },
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Deskripsi',
            labelStyle: GoogleFonts.inter(fontSize: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textLabel,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Row(
          children: ItemStatus.values.map((status) {
            final isSelected = widget.item.status == status;
            final config = _statusConfig(status);

            return Padding(
              padding: const EdgeInsets.only(right: AppDimensions.spacingS),
              child: InkWell(
                onTap: () {
                  setState(() {
                    widget.item.status = status;
                  });
                  widget.onUpdate();
                },
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusCircle),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? config.color.withValues(alpha: 0.15)
                        : AppColors.background,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCircle),
                    border: Border.all(
                      color: isSelected
                          ? config.color
                          : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(config.icon, size: 14, color: config.color),
                      const SizedBox(width: 6),
                      Text(
                        config.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? config.color
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTodoSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, size: 16, color: widget.color),
              const SizedBox(width: 6),
              Text(
                'Todo (${widget.item.completedTodos}/${widget.item.todos.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (widget.item.todos.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: LinearProgressIndicator(
                value: widget.item.todoProgress,
                minHeight: 4,
                backgroundColor: widget.color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingM),
          ...widget.item.todos.asMap().entries.map((entry) {
            return _buildTodoItem(entry.key, entry.value);
          }),
          const SizedBox(height: AppDimensions.spacingS),
          _buildAddTodoField(),
        ],
      ),
    );
  }

  Widget _buildTodoItem(int index, TodoItem todo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                todo.isDone = !todo.isDone;
              });
              widget.onUpdate();
            },
            child: Icon(
              todo.isDone
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: todo.isDone ? widget.color : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              todo.text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: todo.isDone
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
                decoration:
                    todo.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                widget.item.todos.removeAt(index);
              });
              widget.onUpdate();
            },
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTodoField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _todoController,
            style: GoogleFonts.inter(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Tambah todo...',
              hintStyle:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textHint),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusS),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
            ),
            onSubmitted: (_) => _addTodo(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _addTodo,
          icon: Icon(Icons.add_circle_rounded,
              color: widget.color, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _addTodo() {
    final text = _todoController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.item.todos.add(TodoItem(text: text));
      _todoController.clear();
    });
    widget.onUpdate();
  }

  Widget _buildLogSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: widget.color),
              const SizedBox(width: 6),
              Text(
                'Log Proses (${widget.item.logs.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildAddLogField(),
          const SizedBox(height: AppDimensions.spacingM),
          if (widget.item.logs.isEmpty)
            Text(
              'Belum ada log. Catat progress kamu di sini.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...widget.item.logs.reversed.map((log) => _buildLogEntry(log)),
        ],
      ),
    );
  }

  Widget _buildAddLogField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _logController,
            style: GoogleFonts.inter(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Tulis update progress...',
              hintStyle:
                  GoogleFonts.inter(fontSize: 12, color: AppColors.textHint),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusS),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
            ),
            onSubmitted: (_) => _addLog(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _addLog,
          icon: Icon(Icons.send_rounded, color: widget.color, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _addLog() {
    final text = _logController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      widget.item.logs.add(LogEntry(message: text));
      _logController.clear();
    });
    widget.onUpdate();
  }

  Widget _buildLogEntry(LogEntry log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(log.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Hapus Item'),
              content: Text('Yakin ingin menghapus "${widget.item.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onDelete();
                  },
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.delete_outline_rounded, size: 16),
        label: Text(
          'Hapus item',
          style: GoogleFonts.inter(fontSize: 12),
        ),
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
      ),
    );
  }

  _StatusConfig _statusConfig(ItemStatus status) {
    switch (status) {
      case ItemStatus.notStarted:
        return const _StatusConfig(
          label: 'Not Started',
          icon: Icons.radio_button_unchecked_rounded,
          color: AppColors.textMuted,
        );
      case ItemStatus.inProgress:
        return const _StatusConfig(
          label: 'In Progress',
          icon: Icons.pending_rounded,
          color: AppColors.info,
        );
      case ItemStatus.completed:
        return const _StatusConfig(
          label: 'Completed',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        );
    }
  }

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusConfig({
    required this.label,
    required this.icon,
    required this.color,
  });
}
