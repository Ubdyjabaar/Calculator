import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Calculator';
  static const String appVersion = '1.0.0';

  static const double borderRadius = 28;
  static const double borderRadiusSmall = 16;
  static const double borderRadiusLarge = 32;

  static const double blurIntensity = 12;
  static const double glassOpacity = 0.15;

  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);

  static const Color nexaDeepBlue = Color(0xFF0F172A);
  static const Color nexaCyan = Color(0xFF06B6D4);
  static const Color nexaPurple = Color(0xFF7C3AED);
  static const Color nexaSilver = Color(0xFFE2E8F0);
  static const Color darkSurface = nexaDeepBlue;
  static const Color darkCard = Color(0xFF1E293B);
  static const Color glassBorder = Color(0x33FFFFFF);

  static const double keypadSpacing = 8;
  static const double fontSizeResult = 48;
  static const double fontSizeExpression = 20;
  static const double fontSizeScientific = 15;
  static const double fontSizeGraphLabel = 12;

  static const int maxHistoryItems = 500;
  static const int maxDigits = 15;

  static const String dbName = 'calculator.db';
  static const String historyTable = 'history';
}
