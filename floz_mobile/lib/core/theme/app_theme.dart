import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    // Override the entire default text theme with Inter so every widget that
    // reads `Theme.of(context).textTheme.xxx` gets Inter automatically — no
    // widget-level TextStyle overrides needed.
    final interTextTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      displaySmall: AppTypography.displaySmall,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary600,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primary50,
        onPrimaryContainer: AppColors.primary700,
        secondary: AppColors.slate700,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.slate100,
        onSecondaryContainer: AppColors.slate800,
        surface: Colors.white,
        onSurface: AppColors.slate900,
        surfaceContainerHighest: AppColors.slate100,
        outline: AppColors.slate200,
        outlineVariant: AppColors.slate100,
        error: AppColors.danger500,
        onError: Colors.white,
        errorContainer: AppColors.danger50,
      ),
      scaffoldBackgroundColor: AppColors.slate50,
      canvasColor: AppColors.slate50,
      textTheme: interTextTheme,
      primaryTextTheme: interTextTheme,

      // Subtle system nav bar to match scaffold
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.slate50,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.slate900,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: AppColors.slate700, size: 22),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // NavigationBar (Material 3 — used by StudentShell)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary50,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary600 : AppColors.slate400,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.primary600 : AppColors.slate500,
            letterSpacing: 0.2,
          );
        }),
      ),

      // Legacy BottomNavigationBar still themed in case anything uses it
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary600,
        unselectedItemColor: AppColors.slate400,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(color: AppColors.primary600, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(color: AppColors.danger500),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(color: AppColors.danger500, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.slate500,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.primary700,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.slate400),
        helperStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.danger600,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Primary filled button — brand orange, no shadow, strong radius
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.slate200;
            if (states.contains(WidgetState.pressed)) return AppColors.primary700;
            return AppColors.primary600;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.slate400;
            return Colors.white;
          }),
          overlayColor: const WidgetStatePropertyAll(Color(0x1AFFFFFF)),
          elevation: const WidgetStatePropertyAll(0),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          animationDuration: const Duration(milliseconds: 160),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate700,
          side: const BorderSide(color: AppColors.slate200),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary700,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
          side: const BorderSide(color: AppColors.slate200, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.slate100,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.slate900,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary600,
        linearTrackColor: AppColors.slate100,
        circularTrackColor: AppColors.slate100,
      ),

      splashFactory: InkSparkle.splashFactory,
      splashColor: AppColors.primary50,
      highlightColor: AppColors.primary50.withValues(alpha: 0.5),
    );
  }
}
