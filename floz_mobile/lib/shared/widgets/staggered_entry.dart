import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';

/// Fade + translate-up entry animation with per-item stagger delay.
///
/// Wrap each item in a list with this widget and pass its position via
/// [index] to get a cascading reveal (40ms between items by default).
///
/// Based on Emil Kowalski's stagger guidance: keep delays short (30–80ms)
/// so the list feels alive without blocking interaction.
class StaggeredEntry extends StatefulWidget {
  const StaggeredEntry({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = AppMotion.stagger,
    this.duration = const Duration(milliseconds: 320),
    this.offset = 10,
  });

  final int index;
  final Widget child;
  final Duration delayPerItem;
  final Duration duration;
  final double offset;

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: AppMotion.easeOut);
    _translate = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.easeOut),
    );

    final delay = widget.delayPerItem * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _translate, child: widget.child),
    );
  }
}
