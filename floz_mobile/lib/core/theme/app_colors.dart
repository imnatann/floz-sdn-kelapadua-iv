import 'package:flutter/material.dart';

class AppColors {
  // Primary (Orange)
  static const Color primary50 = Color(0xFFFFF7ED);
  static const Color primary100 = Color(0xFFFFEDD5);
  static const Color primary200 = Color(0xFFFED7AA);
  static const Color primary300 = Color(0xFFFDBA74);
  static const Color primary400 = Color(0xFFFB923C);
  static const Color primary500 = Color(0xFFF97316); // MAIN
  static const Color primary600 = Color(0xFFEA580C); // MAIN DARK
  static const Color primary700 = Color(0xFFC2410C);
  static const Color primary800 = Color(0xFF9A3412);
  static const Color primary900 = Color(0xFF7C2D12);

  // Neutral (Slate)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0); // border default
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8); // label/caption text
  static const Color slate500 = Color(0xFF64748B); // secondary text
  static const Color slate600 = Color(0xFF475569); // body text
  static const Color slate700 = Color(0xFF334155); // title text
  static const Color slate800 = Color(0xFF1E293B); // heading text
  static const Color slate900 = Color(0xFF0F172A); // darkest text

  // Aliases for Neutral
  static const Color neutral50 = slate50;
  static const Color neutral100 = slate100;
  static const Color neutral200 = slate200;
  static const Color neutral300 = slate300;
  static const Color neutral400 = slate400;
  static const Color neutral500 = slate500;
  static const Color neutral600 = slate600;
  static const Color neutral700 = slate700;
  static const Color neutral800 = slate800;
  static const Color neutral900 = slate900;

  // Semantic Colors
  // Success (Emerald)
  static const Color success50 = Color(0xFFECFDF5);
  static const Color success500 = Color(0xFF10B981);
  static const Color success600 = Color(0xFF059669);
  static const Color success700 = Color(0xFF047857);

  // Warning (Amber)
  static const Color warning50 = Color(0xFFFFFBEB);
  static const Color warning500 = Color(0xFFF59E0B);
  static const Color warning600 = Color(0xFFD97706);
  static const Color warning700 = Color(0xFFB45309);

  // Danger (Red)
  static const Color danger50 = Color(0xFFFEF2F2);
  static const Color danger500 = Color(0xFFEF4444);
  static const Color danger600 = Color(0xFFDC2626);
  static const Color danger700 = Color(0xFFB91C1C);

  // Info (Blue)
  static const Color info50 = Color(0xFFEFF6FF);
  static const Color info500 = Color(0xFF3B82F6);
  static const Color info600 = Color(0xFF2563EB);
  static const Color info700 = Color(0xFF1D4ED8);

  // Purple (Accent)
  static const Color purple50 = Color(0xFFFAF5FF);
  static const Color purple500 = Color(0xFF8B5CF6);
  static const Color purple600 = Color(0xFF7C3AED);
  static const Color purple700 = Color(0xFF6D28D9);

  // Gradients
  static final LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [slate50, Colors.white, primary50.withValues(alpha: 0.3)],
  );

  static final LinearGradient heroGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary500, warning500],
  );

  static final LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary600],
  );
}
