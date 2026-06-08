import 'package:flutter/material.dart';

/// Central color tokens — only colors used in the app today.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF4E6A);
  static const Color primaryDark = Color(0xFFD63855);
  static const Color primaryGradientStart = Color(0xFFE93B57);
  static const Color primaryDeep = Color(0xFF9E1029);
  static const Color secondary = Color(0xFF6C63FF);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const Color scaffold = Color(0xFFF0F2F8);
  static const Color navy = Color(0xFF1A1D2E);
  static const Color surfaceDark = Color(0xFF252840);
  static const Color failureBackground = Color(0xFF1E101D);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00C48C);
  static const Color warning = Color(0xFFFFBF00);
  static const Color pdf = Colors.blueGrey;
}
