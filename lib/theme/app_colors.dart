import 'package:flutter/material.dart';

/// WhatsApp-inspired color palette with gold/yellow and black for dark mode
class AppColors {
  // Gold / Yellow (primary accent - WhatsApp green equivalent)
  static const Color gold = Color(0xFFD4A017);
  static const Color goldDark = Color(0xFFB8860B);
  static const Color goldLight = Color(0xFFE6C25A);

  // Dark mode colors
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF2A2A2A);
  static const Color darkDivider = Color(0xFF3A3A3A);

  // Light mode colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFECECEC);
  static const Color lightDivider = Color(0xFFDDDDDD);

  // Text colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF757575);

  // Status colors
  static const Color statusActive = Color(0xFF2ECC71);      // green - en cours
  static const Color statusRetrieved = Color(0xFF3498DB);    // blue - récupéré
  static const Color statusNotRetrieved = Color(0xFFE74C3C); // red - non récupéré
  static const Color statusWarning = Color(0xFFF39C12);      // orange - warning
}
