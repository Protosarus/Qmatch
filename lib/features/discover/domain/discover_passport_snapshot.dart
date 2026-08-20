import '../../profile/domain/home_geography.dart';

/// Trusted Discover Passport snapshot from `getDiscoverPassport`.
///
/// [passportEnabled] is the backend **effective** flag (stored AND Resonance).
/// [resonanceAccess] is UX-only for picker/paywall routing — never used to
/// force Discover filters on. Saved [passportCountry]/[passportCity] may remain
/// when access expires.
class DiscoverPassportSnapshot {
  const DiscoverPassportSnapshot({
    required this.resonanceAccess,
    required this.passportEnabled,
    this.passportCountry,
    this.passportCity,
  });

  static const worldwide = DiscoverPassportSnapshot(
    resonanceAccess: false,
    passportEnabled: false,
  );

  /// UX hint from the trusted callable. Not a client entitlement read.
  final bool resonanceAccess;

  /// Effective Passport ON. False when Free or Resonance expired.
  final bool passportEnabled;

  /// ISO-3166-1 alpha-2. May remain when Passport is effectively OFF.
  final String? passportCountry;

  /// Normalized city slug. May remain when Passport is effectively OFF.
  final String? passportCity;

  bool get hasSavedDestination =>
      passportCountry != null && passportCity != null;

  factory DiscoverPassportSnapshot.fromTrustedMap(Map<String, dynamic> raw) {
    return DiscoverPassportSnapshot(
      resonanceAccess: raw['resonance_access'] == true,
      passportEnabled: raw['passport_enabled'] == true,
      passportCountry: HomeGeographyNormalizer.normalizeCountryCode(
        raw['passport_country'] is String
            ? raw['passport_country'] as String
            : null,
      ),
      passportCity: HomeGeographyNormalizer.normalizeCitySlug(
        raw['passport_city'] is String ? raw['passport_city'] as String : null,
      ),
    );
  }
}
