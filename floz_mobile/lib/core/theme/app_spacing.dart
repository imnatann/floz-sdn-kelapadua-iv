import 'package:flutter/material.dart';

class AppSpacing {
  // Base unit: 4px
  static const double space2 = 2.0; // micro
  static const double space4 = 4.0; // xxs
  static const double space6 = 6.0; // xs
  static const double space8 = 8.0; // sm
  static const double space10 = 10.0; // sm+
  static const double space12 = 12.0; // md-
  static const double space16 = 16.0; // md (page padding)
  static const double space20 = 20.0; // md+
  static const double space24 = 24.0; // lg (section spacing)
  static const double space32 = 32.0; // xl
  static const double space40 = 40.0; // 2xl
  static const double space48 = 48.0; // 3xl

  // Standard Paddings
  static const EdgeInsets pagePadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const double sectionGap = 24.0;

  // Radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 6.0;
  static const double radiusMD = 8.0; // inputs, buttons
  static const double radiusLG = 12.0; // cards, modals
  static const double radiusXL = 16.0; // bottom sheets
}
