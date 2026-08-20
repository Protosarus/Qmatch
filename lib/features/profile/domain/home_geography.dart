/// Coarse home geography for later Passport city/country equality queries.
///
/// Derived only from an explicit device location-share Placemark.
/// Never uses raw `location_text` as the query key.
/// Never invents missing country/city.
class HomeGeography {
  const HomeGeography({
    required this.country,
    required this.city,
  });

  /// ISO-3166-1 alpha-2, uppercase (e.g. `TR`, `GB`, `DE`).
  final String country;

  /// Normalized city slug for equality queries (e.g. `istanbul`, `new-york`).
  final String city;
}

/// Pure Placemark view so unit tests do not need the geocoding plugin.
class HomeGeographyPlacemarkInput {
  const HomeGeographyPlacemarkInput({
    this.isoCountryCode,
    this.locality,
    this.administrativeArea,
    this.subAdministrativeArea,
  });

  final String? isoCountryCode;
  final String? locality;
  final String? administrativeArea;
  final String? subAdministrativeArea;
}

/// Country + city derivation from reverse-geocoding.
///
/// City source fallback (first that yields a non-empty slug):
/// 1. `locality` — city
/// 2. `administrativeArea` — province/state
/// 3. `subAdministrativeArea` — district
///
/// City slug: trim → Turkish/Latin fold (İ/I/ı → i, ş→s, ü→u, …) →
/// lowercase ASCII → non `[a-z0-9]` to `-` → collapse/trim hyphens.
///
/// Country: trim → uppercase → must match `^[A-Z]{2}$`.
/// Incomplete pairs return null (do not store a partial home geo).
class HomeGeographyNormalizer {
  HomeGeographyNormalizer._();

  static final RegExp _iso2 = RegExp(r'^[A-Z]{2}$');
  static final RegExp _multiHyphen = RegExp(r'-{2,}');

  static HomeGeography? fromPlacemark(HomeGeographyPlacemarkInput place) {
    final country = normalizeCountryCode(place.isoCountryCode);
    if (country == null) return null;
    final city = citySlugFromFallback(
      locality: place.locality,
      administrativeArea: place.administrativeArea,
      subAdministrativeArea: place.subAdministrativeArea,
    );
    if (city == null) return null;
    return HomeGeography(country: country, city: city);
  }

  static String? normalizeCountryCode(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final upper = trimmed.toUpperCase();
    if (!_iso2.hasMatch(upper)) return null;
    return upper;
  }

  static String? citySlugFromFallback({
    String? locality,
    String? administrativeArea,
    String? subAdministrativeArea,
  }) {
    for (final source in <String?>[
      locality,
      administrativeArea,
      subAdministrativeArea,
    ]) {
      final slug = normalizeCitySlug(source);
      if (slug != null) return slug;
    }
    return null;
  }

  static String? normalizeCitySlug(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final folded = StringBuffer();
    for (final rune in trimmed.runes) {
      if (rune >= 0x0300 && rune <= 0x036F) continue;
      final mapped = _foldChar(rune);
      if (mapped == null) {
        folded.write('-');
        continue;
      }
      folded.write(mapped);
    }
    final slug = folded
        .toString()
        .replaceAll(_multiHyphen, '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) return null;
    return slug;
  }

  static String? _foldChar(int rune) {
    final mapped = _latinFold[rune];
    if (mapped != null) return mapped;
    if (rune >= 65 && rune <= 90) {
      return String.fromCharCode(rune + 32);
    }
    if (rune >= 97 && rune <= 122) {
      return String.fromCharCode(rune);
    }
    if (rune >= 48 && rune <= 57) {
      return String.fromCharCode(rune);
    }
    return null;
  }
}

/// Code-unit fold for Turkish + common Latin letters used in city names.
const Map<int, String> _latinFold = {
  0x00C0: 'a', 0x00C1: 'a', 0x00C2: 'a', 0x00C3: 'a', 0x00C4: 'a', 0x00C5: 'a',
  0x00E0: 'a', 0x00E1: 'a', 0x00E2: 'a', 0x00E3: 'a', 0x00E4: 'a', 0x00E5: 'a',
  0x00C8: 'e', 0x00C9: 'e', 0x00CA: 'e', 0x00CB: 'e',
  0x00E8: 'e', 0x00E9: 'e', 0x00EA: 'e', 0x00EB: 'e',
  0x00CC: 'i', 0x00CD: 'i', 0x00CE: 'i', 0x00CF: 'i',
  0x00EC: 'i', 0x00ED: 'i', 0x00EE: 'i', 0x00EF: 'i',
  0x0130: 'i', // İ
  0x0131: 'i', // ı
  0x00D2: 'o', 0x00D3: 'o', 0x00D4: 'o', 0x00D5: 'o', 0x00D6: 'o', 0x00D8: 'o',
  0x00F2: 'o', 0x00F3: 'o', 0x00F4: 'o', 0x00F5: 'o', 0x00F6: 'o', 0x00F8: 'o',
  0x00D9: 'u', 0x00DA: 'u', 0x00DB: 'u', 0x00DC: 'u',
  0x00F9: 'u', 0x00FA: 'u', 0x00FB: 'u', 0x00FC: 'u',
  0x00C7: 'c', 0x00E7: 'c',
  0x011E: 'g', 0x011F: 'g', // Ğ ğ
  0x015E: 's', 0x015F: 's', // Ş ş
  0x00D1: 'n', 0x00F1: 'n',
  0x00DD: 'y', 0x00FD: 'y', 0x00FF: 'y',
  0x00DF: 'ss',
  0x00C6: 'ae', 0x00E6: 'ae',
  0x0152: 'oe', 0x0153: 'oe',
};
