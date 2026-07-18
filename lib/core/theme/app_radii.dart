import 'package:flutter/material.dart';

/// Border radius scale for Premium Cosmic Minimal (DS-0).
class AppRadii {
  AppRadii._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;

  /// Buttons / inputs (theme foundation).
  static const double button = md;

  /// Cards / dialogs.
  static const double card = lg;

  /// Large sheets / hero panels.
  static const double sheet = xl;

  static BorderRadius get buttonBorder => BorderRadius.circular(button);
  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get sheetBorder => BorderRadius.circular(sheet);
  static BorderRadius get pillBorder => BorderRadius.circular(pill);

  /// Profile / CosmicProfileHero portrait is a circle (geometry, not radius token).
  static const BoxShape profileHeroShape = BoxShape.circle;
}
