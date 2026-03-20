import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Widget angka yang animasi naik dari 0 ke target saat masuk viewport.
/// Digunakan di stats section untuk menampilkan trust metrics.
class AnimatedCounterWidget extends StatefulWidget {
  final int target;
  final String suffix;
  final String prefix;
  final String label;
  final Duration duration;
  final Color? accentColor;

  const AnimatedCounterWidget({
    super.key,
    required this.target,
    required this.label,
    this.suffix = '',
    this.prefix = '',
    this.duration = const Duration(milliseconds: 2000),
    this.accentColor,
  });

  @override
  State<AnimatedCounterWidget> createState() => _AnimatedCounterWidgetState();
}

class _AnimatedCounterWidgetState extends State<AnimatedCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('counter_${widget.label}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.3) _startAnimation();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              final value = (_animation.value * widget.target).round();
              return ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: Text(
                  '${widget.prefix}${_formatNumber(value)}${widget.suffix}',
                  style: AppTextStyles.statNumber.copyWith(
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: AppTextStyles.statLabel,
            textAlign: TextAlign.center,
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: 200.ms)
          .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 200.ms),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}
