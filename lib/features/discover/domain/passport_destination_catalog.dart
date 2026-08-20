import '../../profile/domain/home_geography.dart';

/// One selectable Passport destination (v1 catalog — no GPS / map / geohash).
class PassportDestination {
  const PassportDestination({
    required this.countryCode,
    required this.citySlug,
    required this.cityEn,
    required this.cityTr,
    required this.countryEn,
    required this.countryTr,
  });

  final String countryCode;
  final String citySlug;
  final String cityEn;
  final String cityTr;
  final String countryEn;
  final String countryTr;

  String cityLabel(bool turkish) => turkish ? cityTr : cityEn;

  String countryLabel(bool turkish) => turkish ? countryTr : countryEn;

  String listLabel(bool turkish) =>
      '${cityLabel(turkish)}, ${countryLabel(turkish)}';
}

/// Curated v1 city/country catalog for Passport search/select.
class PassportDestinationCatalog {
  PassportDestinationCatalog._();

  static PassportDestination _d({
    required String country,
    required String cityEn,
    required String cityTr,
    required String countryEn,
    required String countryTr,
  }) {
    final slug = HomeGeographyNormalizer.normalizeCitySlug(cityEn);
    if (slug == null) {
      throw StateError('Passport catalog city has no slug: $cityEn');
    }
    return PassportDestination(
      countryCode: country,
      citySlug: slug,
      cityEn: cityEn,
      cityTr: cityTr,
      countryEn: countryEn,
      countryTr: countryTr,
    );
  }

  static final List<PassportDestination> cities = List.unmodifiable([
    _d(
      country: 'TR',
      cityEn: 'Istanbul',
      cityTr: 'İstanbul',
      countryEn: 'Turkey',
      countryTr: 'Türkiye',
    ),
    _d(
      country: 'TR',
      cityEn: 'Ankara',
      cityTr: 'Ankara',
      countryEn: 'Turkey',
      countryTr: 'Türkiye',
    ),
    _d(
      country: 'TR',
      cityEn: 'Izmir',
      cityTr: 'İzmir',
      countryEn: 'Turkey',
      countryTr: 'Türkiye',
    ),
    _d(
      country: 'TR',
      cityEn: 'Antalya',
      cityTr: 'Antalya',
      countryEn: 'Turkey',
      countryTr: 'Türkiye',
    ),
    _d(
      country: 'TR',
      cityEn: 'Bursa',
      cityTr: 'Bursa',
      countryEn: 'Turkey',
      countryTr: 'Türkiye',
    ),
    _d(
      country: 'GB',
      cityEn: 'London',
      cityTr: 'Londra',
      countryEn: 'United Kingdom',
      countryTr: 'Birleşik Krallık',
    ),
    _d(
      country: 'GB',
      cityEn: 'Manchester',
      cityTr: 'Manchester',
      countryEn: 'United Kingdom',
      countryTr: 'Birleşik Krallık',
    ),
    _d(
      country: 'DE',
      cityEn: 'Berlin',
      cityTr: 'Berlin',
      countryEn: 'Germany',
      countryTr: 'Almanya',
    ),
    _d(
      country: 'DE',
      cityEn: 'Munich',
      cityTr: 'Münih',
      countryEn: 'Germany',
      countryTr: 'Almanya',
    ),
    _d(
      country: 'DE',
      cityEn: 'Hamburg',
      cityTr: 'Hamburg',
      countryEn: 'Germany',
      countryTr: 'Almanya',
    ),
    _d(
      country: 'US',
      cityEn: 'New York',
      cityTr: 'New York',
      countryEn: 'United States',
      countryTr: 'ABD',
    ),
    _d(
      country: 'US',
      cityEn: 'Los Angeles',
      cityTr: 'Los Angeles',
      countryEn: 'United States',
      countryTr: 'ABD',
    ),
    _d(
      country: 'US',
      cityEn: 'Chicago',
      cityTr: 'Chicago',
      countryEn: 'United States',
      countryTr: 'ABD',
    ),
    _d(
      country: 'US',
      cityEn: 'Miami',
      cityTr: 'Miami',
      countryEn: 'United States',
      countryTr: 'ABD',
    ),
    _d(
      country: 'US',
      cityEn: 'San Francisco',
      cityTr: 'San Francisco',
      countryEn: 'United States',
      countryTr: 'ABD',
    ),
    _d(
      country: 'FR',
      cityEn: 'Paris',
      cityTr: 'Paris',
      countryEn: 'France',
      countryTr: 'Fransa',
    ),
    _d(
      country: 'ES',
      cityEn: 'Madrid',
      cityTr: 'Madrid',
      countryEn: 'Spain',
      countryTr: 'İspanya',
    ),
    _d(
      country: 'ES',
      cityEn: 'Barcelona',
      cityTr: 'Barcelona',
      countryEn: 'Spain',
      countryTr: 'İspanya',
    ),
    _d(
      country: 'IT',
      cityEn: 'Rome',
      cityTr: 'Roma',
      countryEn: 'Italy',
      countryTr: 'İtalya',
    ),
    _d(
      country: 'IT',
      cityEn: 'Milan',
      cityTr: 'Milano',
      countryEn: 'Italy',
      countryTr: 'İtalya',
    ),
    _d(
      country: 'NL',
      cityEn: 'Amsterdam',
      cityTr: 'Amsterdam',
      countryEn: 'Netherlands',
      countryTr: 'Hollanda',
    ),
    _d(
      country: 'AE',
      cityEn: 'Dubai',
      cityTr: 'Dubai',
      countryEn: 'United Arab Emirates',
      countryTr: 'BAE',
    ),
    _d(
      country: 'JP',
      cityEn: 'Tokyo',
      cityTr: 'Tokyo',
      countryEn: 'Japan',
      countryTr: 'Japonya',
    ),
    _d(
      country: 'AU',
      cityEn: 'Sydney',
      cityTr: 'Sidney',
      countryEn: 'Australia',
      countryTr: 'Avustralya',
    ),
    _d(
      country: 'CA',
      cityEn: 'Toronto',
      cityTr: 'Toronto',
      countryEn: 'Canada',
      countryTr: 'Kanada',
    ),
    _d(
      country: 'SE',
      cityEn: 'Stockholm',
      cityTr: 'Stockholm',
      countryEn: 'Sweden',
      countryTr: 'İsveç',
    ),
    _d(
      country: 'PT',
      cityEn: 'Lisbon',
      cityTr: 'Lizbon',
      countryEn: 'Portugal',
      countryTr: 'Portekiz',
    ),
    _d(
      country: 'GR',
      cityEn: 'Athens',
      cityTr: 'Atina',
      countryEn: 'Greece',
      countryTr: 'Yunanistan',
    ),
    _d(
      country: 'AT',
      cityEn: 'Vienna',
      cityTr: 'Viyana',
      countryEn: 'Austria',
      countryTr: 'Avusturya',
    ),
    _d(
      country: 'CH',
      cityEn: 'Zurich',
      cityTr: 'Zürih',
      countryEn: 'Switzerland',
      countryTr: 'İsviçre',
    ),
    _d(
      country: 'IE',
      cityEn: 'Dublin',
      cityTr: 'Dublin',
      countryEn: 'Ireland',
      countryTr: 'İrlanda',
    ),
    _d(
      country: 'CZ',
      cityEn: 'Prague',
      cityTr: 'Prag',
      countryEn: 'Czechia',
      countryTr: 'Çekya',
    ),
    _d(
      country: 'PL',
      cityEn: 'Warsaw',
      cityTr: 'Varşova',
      countryEn: 'Poland',
      countryTr: 'Polonya',
    ),
    _d(
      country: 'KR',
      cityEn: 'Seoul',
      cityTr: 'Seul',
      countryEn: 'South Korea',
      countryTr: 'Güney Kore',
    ),
    _d(
      country: 'SG',
      cityEn: 'Singapore',
      cityTr: 'Singapur',
      countryEn: 'Singapore',
      countryTr: 'Singapur',
    ),
    _d(
      country: 'BR',
      cityEn: 'Sao Paulo',
      cityTr: 'São Paulo',
      countryEn: 'Brazil',
      countryTr: 'Brezilya',
    ),
    _d(
      country: 'MX',
      cityEn: 'Mexico City',
      cityTr: 'Meksiko',
      countryEn: 'Mexico',
      countryTr: 'Meksika',
    ),
    _d(
      country: 'IN',
      cityEn: 'Mumbai',
      cityTr: 'Mumbai',
      countryEn: 'India',
      countryTr: 'Hindistan',
    ),
    _d(
      country: 'EG',
      cityEn: 'Cairo',
      cityTr: 'Kahire',
      countryEn: 'Egypt',
      countryTr: 'Mısır',
    ),
    _d(
      country: 'ZA',
      cityEn: 'Cape Town',
      cityTr: 'Cape Town',
      countryEn: 'South Africa',
      countryTr: 'Güney Afrika',
    ),
  ]);

  static PassportDestination? find({
    required String? country,
    required String? citySlug,
  }) {
    if (country == null || citySlug == null) return null;
    for (final city in cities) {
      if (city.countryCode == country && city.citySlug == citySlug) {
        return city;
      }
    }
    return null;
  }

  /// User-facing city label. Never returns the raw slug.
  static String displayCity({
    required String? country,
    required String? citySlug,
    required bool turkish,
  }) {
    final hit = find(country: country, citySlug: citySlug);
    if (hit != null) return hit.cityLabel(turkish);
    return friendlyCityFromSlug(citySlug);
  }

  /// Title-case hyphenated slug for unknown catalog cities. Not UI slug text.
  static String friendlyCityFromSlug(String? slug) {
    if (slug == null || slug.trim().isEmpty) return '';
    return slug.split('-').where((part) => part.isNotEmpty).map((part) {
      return '${part[0].toUpperCase()}${part.substring(1)}';
    }).join(' ');
  }

  static List<PassportDestination> search(String query, {required bool turkish}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<PassportDestination>.from(cities);
    return cities.where((city) {
      return city.cityEn.toLowerCase().contains(q) ||
          city.cityTr.toLowerCase().contains(q) ||
          city.countryEn.toLowerCase().contains(q) ||
          city.countryTr.toLowerCase().contains(q) ||
          city.countryCode.toLowerCase().contains(q) ||
          city.citySlug.contains(q);
    }).toList(growable: false);
  }
}
