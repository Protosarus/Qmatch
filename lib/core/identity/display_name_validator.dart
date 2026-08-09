import 'package:characters/characters.dart';

import 'display_name_contract.dart';

enum DisplayNameValidationError {
  empty,
  tooShort,
  tooLong,
  missingLetterOrNumber,
  controlCharacters,
  emailLike,
  phoneLike,
  urlLike,
}

class DisplayNameValidationResult {
  const DisplayNameValidationResult.ok(this.normalized) : error = null;

  const DisplayNameValidationResult.invalid(this.error) : normalized = null;

  final String? normalized;
  final DisplayNameValidationError? error;

  bool get isValid =>
      error == null && normalized != null && normalized!.isNotEmpty;
}

/// Shared normalize + validate for public display names.
class DisplayNameValidator {
  DisplayNameValidator._();

  /// Trim, collapse internal whitespace, reject multiline.
  static String normalize(String input) {
    final noBreaks = input.replaceAll(RegExp(r'[\r\n\t]+'), ' ');
    return noBreaks.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static DisplayNameValidationResult validate(String input) {
    if (_hasControlCharacters(input)) {
      return const DisplayNameValidationResult.invalid(
        DisplayNameValidationError.controlCharacters,
      );
    }

    final normalized = normalize(input);
    if (normalized.isEmpty) {
      return const DisplayNameValidationResult.invalid(
        DisplayNameValidationError.empty,
      );
    }

    final graphemes = normalized.characters.length;
    if (graphemes < DisplayNameContract.minGraphemes) {
      return const DisplayNameValidationResult.invalid(
        DisplayNameValidationError.tooShort,
      );
    }
    if (graphemes > DisplayNameContract.maxGraphemes) {
      return const DisplayNameValidationResult.invalid(
        DisplayNameValidationError.tooLong,
      );
    }

    if (_isEmailLike(normalized)) {
      return const DisplayNameValidationResult.invalid(
        DisplayNameValidationError.emailLike,
      );
    }
    if (_isPhoneLike(normalized)) {
      return const DisplayNameValidationResult.invalid(
        DisplayNameValidationError.phoneLike,
      );
    }
    if (_isUrlLike(normalized)) {
      return const DisplayNameValidationResult.invalid(
        DisplayNameValidationError.urlLike,
      );
    }

    if (!_hasLetterOrNumber(normalized)) {
      return const DisplayNameValidationResult.invalid(
        DisplayNameValidationError.missingLetterOrNumber,
      );
    }

    return DisplayNameValidationResult.ok(normalized);
  }

  static bool _hasControlCharacters(String input) {
    for (final unit in input.codeUnits) {
      if (unit < 0x20 || unit == 0x7F) return true;
    }
    return false;
  }

  static bool _hasLetterOrNumber(String input) {
    return RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(input);
  }

  static bool _isEmailLike(String input) {
    // Obvious email-only shape (not a ban on '@' inside nicknames unless whole value is email).
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input);
  }

  static bool _isPhoneLike(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return false;
    // Entire value is punctuation/spaces/plus around digits only.
    final withoutPhoneNoise = input.replaceAll(RegExp(r'[\d\s+\-().]'), '');
    return withoutPhoneNoise.isEmpty && digits.length >= 8;
  }

  static bool _isUrlLike(String input) {
    final lower = input.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return true;
    }
    if (lower.startsWith('www.')) return true;
    return RegExp(r'^[a-z0-9-]+\.(com|net|org|io|co|app)(/.*)?$',
            caseSensitive: false)
        .hasMatch(input);
  }

  /// Read-path: safe to show publicly (not contact-like / empty).
  /// Does not enforce 2–24 grapheme write bounds.
  static bool isSafePublicDisplay(String normalized) {
    if (normalized.isEmpty) return false;
    if (_hasControlCharacters(normalized)) return false;
    if (_isEmailLike(normalized)) return false;
    if (_isPhoneLike(normalized)) return false;
    if (_isUrlLike(normalized)) return false;
    if (!_hasLetterOrNumber(normalized)) return false;
    return true;
  }
}
