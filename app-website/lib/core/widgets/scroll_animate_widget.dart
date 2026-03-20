import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Wrapper yang menambahkan animasi fade+slide saat widget masuk viewport.
/// Gunakan untuk section-section di homepage agar muncul saat di-scroll.
class ScrollAnimateWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideOffset;
  final Axis slideAxis;
  final String? uniqueKey;

  const ScrollAnimateWidget({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.slideOffset = 40.0,
    this.slideAxis = Axis.vertical,
    this.uniqueKey,
  });

  @override
  State<ScrollAnimateWidget> createState() => _ScrollAnimateWidgetState();
}

class _ScrollAnimateWidgetState extends State<ScrollAnimateWidget> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.uniqueKey ?? widget.child.hashCode.toString()),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_visible) {
          setState(() => _visible = true);
        }
      },
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _visible
              ? Offset.zero
              : widget.slideAxis == Axis.vertical
                  ? Offset(0, widget.slideOffset / 200)
                  : Offset(widget.slideOffset / 200, 0),
          duration: widget.duration,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Animasi stagger untuk list item — setiap item muncul bergiliran.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration baseDelay;
  final Duration itemDelay;
  final Duration duration;

  const StaggeredList({
    super.key,
    required this.children,
    this.baseDelay = const Duration(milliseconds: 100),
    this.itemDelay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final delay = baseDelay + (itemDelay * entry.key);
        return entry.value
            .animate(delay: delay)
            .fadeIn(duration: duration)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: duration,
              curve: Curves.easeOut,
            );
      }).toList(),
    );
  }
}
