import 'package:flutter/material.dart';

/// Design tokens extracted directly from Penpot design and inspection report.
class AppColors {
  // Brand
  static const Color primaryBlue = Color(0xFF2562DB);
  static const Color primaryBlueHover = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFFEFF6FF);

  static const Color secondaryTeal = Color(0xFF00AAC7);
  static const Color secondaryTealLight = Color(0xFFE0F7FA);

  // Status & Severities
  static const Color criticalRed = Color(0xFFDB322E);
  static const Color criticalRedLight = Color(0xFFFDE8E8);

  static const Color majorOrange = Color(0xFFEF7D21);
  static const Color majorOrangeLight = Color(0xFFFFF4E5);

  static const Color minorYellow = Color(0xFFE8B81B);
  static const Color minorYellowLight = Color(0xFFFEF9C3);

  static const Color normalGreen = Color(0xFF2E9D57);
  static const Color normalGreenLight = Color(0xFFDCFCE7);

  static const Color notSeenGrey = Color(0xFF777777);
  static const Color notSeenGreyLight = Color(0xFFF1F5F9);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color darkBar = Color(0xFF0F172A);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFFCBD5E1);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textOnDark = Colors.white;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Segoe UI, Roboto, Helvetica, Arial, sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
