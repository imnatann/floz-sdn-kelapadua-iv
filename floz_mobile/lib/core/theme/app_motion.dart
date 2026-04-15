import 'package:flutter/animation.dart';

/// Centralized motion tokens. Use these instead of ad-hoc durations/curves
/// so animation feel stays cohesive across the app.
///
/// Principles:
/// - UI transitions stay under 300ms
/// - Press feedback is 120–160ms
/// - Enter/exit uses easeOutCubic (strong, responsive)
/// - Stagger between list items: 40–60ms
class AppMotion {
  AppMotion._();

  // ── Durations ────────────────────────────────────────────────────
  static const Duration pressIn      = Duration(milliseconds: 120);
  static const Duration pressOut     = Duration(milliseconds: 180);
  static const Duration fast         = Duration(milliseconds: 160);
  static const Duration medium       = Duration(milliseconds: 220);
  static const Duration slow         = Duration(milliseconds: 320);
  static const Duration stagger      = Duration(milliseconds: 50);
  static const Duration pageTransition = Duration(milliseconds: 260);

  // ── Curves (Emil's strong custom variants) ───────────────────────
  /// Strong ease-out: starts fast, settles. Use for entrances, hovers.
  /// cubic-bezier(0.23, 1, 0.32, 1)
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Strong ease-in-out: smooth acceleration/deceleration.
  /// cubic-bezier(0.77, 0, 0.175, 1)
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// iOS-style drawer curve.
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  /// Button press response.
  static const Curve press = Curves.easeOutCubic;
}
