import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark({Color seedColor = AppConstants.nexaCyan}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: AppConstants.nexaDeepBlue,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppConstants.nexaDeepBlue,
      brightness: Brightness.dark,
      cardTheme: CardThemeData(
        color: AppConstants.darkCard,
        elevation: 8,
        shadowColor: colorScheme.primary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppConstants.nexaSilver,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF94A3B8), size: 24),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w300,
          color: AppConstants.nexaSilver,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w300,
          color: AppConstants.nexaSilver,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppConstants.nexaSilver.withValues(alpha: 0.7),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppConstants.nexaSilver.withValues(alpha: 0.7),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppConstants.nexaSilver.withValues(alpha: 0.6),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppConstants.nexaSilver.withValues(alpha: 0.5),
          letterSpacing: 1.0,
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF94A3B8), size: 24),
      dividerTheme: const DividerThemeData(
        color: Color(0x1FFFFFFF),
        thickness: 0.5,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return Colors.white.withValues(alpha: 0.5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.3);
          }
          return Colors.white.withValues(alpha: 0.1);
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppConstants.nexaDeepBlue,
        surfaceTintColor: Colors.transparent,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          colorScheme.primary.withValues(alpha: 0.5),
        ),
        trackColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.05),
        ),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(8),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  static ThemeData light({Color seedColor = AppConstants.nexaCyan}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      brightness: Brightness.light,
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: AppConstants.nexaDeepBlue.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppConstants.nexaDeepBlue,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF475569), size: 24),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w300,
          color: AppConstants.nexaDeepBlue,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.w300,
          color: AppConstants.nexaDeepBlue,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppConstants.nexaDeepBlue.withValues(alpha: 0.7),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppConstants.nexaDeepBlue.withValues(alpha: 0.7),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppConstants.nexaDeepBlue.withValues(alpha: 0.6),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppConstants.nexaDeepBlue.withValues(alpha: 0.5),
          letterSpacing: 1.0,
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF475569), size: 24),
      dividerTheme: const DividerThemeData(
        color: Color(0x1A000000),
        thickness: 0.5,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
