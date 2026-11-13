import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryDark = Color(0xFF004ECC);
  static const Color primaryLight = Color(0xFF4A90E2);
  static const Color accent = Color(0xFF00D2FF);

  // Engineering Dark Slate Palette
  static const Color darkBg = Color(0xFF0B0F17);
  static const Color darkSurface = Color(0xFF131B26);
  static const Color darkCard = Color(0xFF1B2433);
  static const Color darkBorder = Color(0xFF263347);
  static const Color darkText = Color(0xFFE6EDF5);
  static const Color darkTextMuted = Color(0xFF8B9CB3);

  // Light Palette
  static const Color lightBg = Color(0xFFF4F6F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFD6DFEB);
  static const Color lightText = Color(0xFF101828);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Status & Engineering Limits (Trap Seal ±25mm WG)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Physical Flow & Simulation Colors
  static const Color pipeStack = Color(0xFF38BDF8);
  static const Color pipePrl = Color(0xFFFACC15);
  static const Color pipeDrain = Color(0xFF6366F1);
  static const Color waterFlow = Color(0xFF00E5FF);
  static const Color waterStagnant = Color(0xFF0284C7);
  static const Color airRelief = Color(0xFFFEF08A);
  static const Color pressurePositive = Color(0xFFFF4D4F); // Red glow
  static const Color pressureNegative = Color(0xFF1890FF); // Blue glow
  static const Color fittingCoupler = Color(0xFF10B981); // Green diamond
}
