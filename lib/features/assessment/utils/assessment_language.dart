import 'package:flutter/widgets.dart';

/// Resolves assessment language metadata for Firestore (`language_used` / `locale_used`).
///
/// Currently supports `en` and `tr` only. Unsupported languages fall back to `en`.
class AssessmentLanguage {
  const AssessmentLanguage._();

  static const supported = {'en', 'tr'};

  /// Normalized language code: `en` or `tr`.
  static String languageUsed({
    BuildContext? context,
    String? languageCode,
  }) {
    final raw = (languageCode ??
            (context != null
                ? Localizations.maybeLocaleOf(context)?.languageCode
                : null) ??
            _platformLanguageCode())
        .trim()
        .toLowerCase();

    if (raw.isEmpty) return 'en';
    if (supported.contains(raw)) return raw;
    // e.g. en_US → en
    final primary = raw.split(RegExp(r'[_-]')).first;
    if (supported.contains(primary)) return primary;
    return 'en';
  }

  /// Best-effort locale tag, e.g. `tr_TR` / `en_US`.
  static String localeUsed({
    BuildContext? context,
    Locale? locale,
  }) {
    final loc = locale ??
        (context != null ? Localizations.maybeLocaleOf(context) : null) ??
        _platformLocale();

    final lang = languageUsed(
      languageCode: loc.languageCode,
    );
    final country = (loc.countryCode ?? '').trim().toUpperCase();
    if (country.isNotEmpty) {
      return '${lang}_$country';
    }
    // Sensible defaults when country is missing.
    if (lang == 'tr') return 'tr_TR';
    return 'en_US';
  }

  static String _platformLanguageCode() {
    try {
      return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    } catch (_) {
      return 'en';
    }
  }

  static Locale _platformLocale() {
    try {
      return WidgetsBinding.instance.platformDispatcher.locale;
    } catch (_) {
      return const Locale('en', 'US');
    }
  }
}
