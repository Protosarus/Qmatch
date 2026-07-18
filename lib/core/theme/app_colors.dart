import 'package:flutter/material.dart';

/// Qmatch Premium Cosmic Minimal color tokens (DS-0).
///
/// Existing aliases ([primary], [background], etc.) are preserved so current
/// screens keep compiling without a redesign pass.
class AppColors {
  AppColors._();

  // ── Cosmic canvas ─────────────────────────────────────────────────────────
  /// App canvas (bg.void).
  static const Color cosmicBlack = Color(0xFF0C0C0C);
  /// Elevated night / atmospheric top wash (bg.deep).
  static const Color midnightNavy = Color(0xFF0A0F1C);
  static const Color deepIndigo = Color(0xFF161B3A);
  static const Color cosmicPurple = Color(0xFF5B4B8A);
  static const Color electricBlue = Color(0xFF4F7CFF);
  static const Color resonanceViolet = Color(0xFF7C6CFF);

  /// Dimmed control opacity (buttons / icons when disabled).
  static const double disabledOpacity = 0.4;

  // ── Gold accents ──────────────────────────────────────────────────────────
  static const Color softGold = Color(0xFFE3C565);
  static const Color warmGold = Color(0xFFC9A227);

  // ── Glass / surfaces ──────────────────────────────────────────────────────
  /// Soft translucent panel over void (use with BackdropFilter later if needed).
  static const Color glassSurface = Color(0x99141A2E);
  static const Color glassSurfaceStrong = Color(0xCC1A2240);
  static const Color surfaceElevated = Color(0xFF1A1A1A);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color borderSubtle = Color(0x33A8B0D0);
  static const Color borderGlow = Color(0x66E3C565);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF7A7A8A);
  static const Color textGold = softGold;

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color danger = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4ECDC4);
  static const Color warning = Color(0xFFF5B942);

  // ── Neo Lab viz channels (IQ / EQ / Frequency only) ───────────────────────
  static const Color vizIq = Color(0xFF6B8CFF);
  static const Color vizEq = Color(0xFF9B7CFF);
  static const Color vizFrequency = Color(0xFF5EC8D8);

  // ── Backward-compatible aliases (do not remove without screen migration) ─
  static const Color primary = softGold;
  static const Color secondary = Color(0xFFD946EF);
  static const Color background = cosmicBlack;
  static const Color surface = surfaceElevated;
  static const Color accent = softGold;
  static const Color error = danger;
  static const Color buttonOutline = softGold;
  static const Color buttonText = softGold;
}
