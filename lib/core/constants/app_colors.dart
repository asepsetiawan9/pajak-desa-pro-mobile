import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (SIPABAR Royal Blue & Deep Navy)
  static const Color primary = Color(0xFF0062C4); // Royal Blue
  static const Color primaryDark = Color(0xFF003D8D); // Deep Navy Blue
  static const Color primaryLight = Color(0xFF00A3FF); // Bright Sky Blue
  static const Color accent = Color(0xFFF59E0B); // Amber Gold
  static const Color accentDark = Color(0xFFD97706); // Warm Amber Orange
  static const Color accentLight = Color(0xFFFECE0E); // Bright Gold Yellow

  // Light Surface & Backgrounds (Crisp White & Slate Tones)
  static const Color background = Color(0xFFF8FAFC); // Crisp Light Gray
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceCard = Color(0xFFF1F5F9); // Light Gray Input Card
  static const Color glassBorder = Color(0xFFE2E8F0); // Subtle Border
  static const Color cardBorder = Color(0xFFE2E8F0); // Card Border
  static const Color inputBorder = Color(0xFFCBD5E1); // Input Border

  // Functional Status Colors
  static const Color success = Color(0xFF10B981); // Emerald (LUNAS)
  static const Color successBg = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFEF4444); // Red (BELUM)
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF00A3FF); // Sky Blue

  // Typography Text Colors (High Contrast Slate)
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate Headings
  static const Color textSecondary = Color(0xFF334155); // Slate Body
  static const Color textMuted = Color(0xFF64748B); // Muted Slate

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF003D8D), Color(0xFF0075D5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
