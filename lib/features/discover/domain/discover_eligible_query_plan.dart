import 'discover_passport_snapshot.dart';

/// Discover eligibility query derived from trusted Passport.
///
/// OFF → existing global `discover_eligible == true`.
/// ON with dest → same plus `home_country` + `home_city`.
/// ON without dest → empty pool, never a silent Worldwide fallback.
class DiscoverEligibleQueryPlan {
  const DiscoverEligibleQueryPlan._({
    required this.passportActive,
    this.country,
    this.city,
  });

  const DiscoverEligibleQueryPlan.worldwide()
      : this._(passportActive: false);

  const DiscoverEligibleQueryPlan.destination({
    required String country,
    required String city,
  }) : this._(passportActive: true, country: country, city: city);

  const DiscoverEligibleQueryPlan.emptyDestination()
      : this._(passportActive: true);

  final bool passportActive;
  final String? country;
  final String? city;

  bool get usesDestinationFilter =>
      passportActive && country != null && city != null;

  /// Passport is effectively ON but dest keys are missing — do not query global.
  bool get skipEligibleQuery =>
      passportActive && (country == null || city == null);

  factory DiscoverEligibleQueryPlan.fromPassport(
    DiscoverPassportSnapshot snapshot,
  ) {
    if (!snapshot.passportEnabled) {
      return const DiscoverEligibleQueryPlan.worldwide();
    }
    final country = snapshot.passportCountry;
    final city = snapshot.passportCity;
    if (country == null || city == null) {
      return const DiscoverEligibleQueryPlan.emptyDestination();
    }
    return DiscoverEligibleQueryPlan.destination(
      country: country,
      city: city,
    );
  }
}
