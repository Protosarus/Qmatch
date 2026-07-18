/// Spacing scale for Premium Cosmic Minimal (DS-0).
///
/// Base scale: 4 · 8 · 12 · 16 · 24 · 32 · 48.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Default screen horizontal inset.
  static const double screenHorizontal = lg;

  /// Default card / glass panel internal padding.
  static const double cardPadding = md;

  /// Comfortable card internal padding (upper end of 16–20).
  static const double cardPaddingComfortable = 20;

  /// Primary CTA vertical padding (pairs with [AppRadii.button]).
  static const double buttonVertical = md;

  /// Primary CTA horizontal padding.
  static const double buttonHorizontal = xl;
}
