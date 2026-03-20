import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Tombol dengan gradient indigo → violet.
/// Digunakan sebagai CTA utama di seluruh website.
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double height;
  final double horizontalPadding;
  final double borderRadius;
  final IconData? icon;
  final LinearGradient? gradient;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 56,
    this.horizontalPadding = 32,
    this.borderRadius = 12,
    this.icon,
    this.gradient,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() => _hovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: widget.height,
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
            decoration: BoxDecoration(
              gradient: widget.gradient ?? AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.brandIndigo.withValues(alpha: 0.5),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.brandIndigo.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTextStyles.btnM.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol outline (secondary CTA).
class OutlineButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double height;
  final double horizontalPadding;
  final IconData? icon;

  const OutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 56,
    this.horizontalPadding = 32,
    this.icon,
  });

  @override
  State<OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.glassBackground
                : Colors.transparent,
            border: Border.all(
              color: _hovered ? AppColors.brandIndigo : AppColors.borderLight,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: AppColors.textPrimary, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppTextStyles.btnM.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
