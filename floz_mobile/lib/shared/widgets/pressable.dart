import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';

/// Wraps any child with a subtle scale-down-on-press feedback.
///
/// Follows Emil Kowalski's "buttons must feel responsive" rule:
/// — scale 0.97 on press, 160ms easeOutCubic
/// — also triggers on keyboard focus + pointer down on touch devices
///
/// Use this for any tappable element that isn't already a Material button
/// (cards, list items, custom CTAs).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.behavior = HitTestBehavior.opaque,
    this.enableHaptics = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HitTestBehavior behavior;
  final bool enableHaptics;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTap: enabled ? widget.onTap : null,
      onLongPress: enabled ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: _pressed ? AppMotion.pressIn : AppMotion.pressOut,
        curve: AppMotion.press,
        child: widget.child,
      ),
    );
  }
}
