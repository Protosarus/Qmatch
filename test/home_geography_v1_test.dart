import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/profile/domain/home_geography.dart';
import 'package:qmatch/features/profile/models/user_profile_model.dart';

void main() {
  group('HomeGeographyNormalizer', () {
    test('Turkish location -> TR + istanbul', () {
      final geo = HomeGeographyNormalizer.fromPlacemark(
        const HomeGeographyPlacemarkInput(
          isoCountryCode: 'tr',
          locality: 'İstanbul',
          administrativeArea: 'İstanbul',
          subAdministrativeArea: 'Kadıköy',
        ),
      );
      expect(geo, isNotNull);
      expect(geo!.country, 'TR');
      expect(geo.city, 'istanbul');
    });

    test('different casing and diacritics normalize consistently', () {
      const variants = [
        'İstanbul',
        'ISTANBUL',
        'istanbul',
        'Istanbul',
      ];
      final slugs = [
        for (final v in variants) HomeGeographyNormalizer.normalizeCitySlug(v),
      ];
      expect(slugs.toSet(), {'istanbul'});

      expect(HomeGeographyNormalizer.normalizeCitySlug('München'), 'munchen');
      expect(HomeGeographyNormalizer.normalizeCitySlug('MUNCHEN'), 'munchen');
      expect(HomeGeographyNormalizer.normalizeCitySlug('Köln'), 'koln');
      expect(HomeGeographyNormalizer.normalizeCitySlug('Şişli'), 'sisli');
      expect(HomeGeographyNormalizer.normalizeCitySlug('New York'), 'new-york');
      expect(
        HomeGeographyNormalizer.normalizeCountryCode('gb'),
        'GB',
      );
      expect(
        HomeGeographyNormalizer.normalizeCountryCode('DE'),
        'DE',
      );
    });

    test('missing locality uses administrativeArea then subAdministrativeArea',
        () {
      final fromAdmin = HomeGeographyNormalizer.fromPlacemark(
        const HomeGeographyPlacemarkInput(
          isoCountryCode: 'DE',
          locality: null,
          administrativeArea: 'München',
          subAdministrativeArea: 'Altstadt',
        ),
      );
      expect(fromAdmin!.country, 'DE');
      expect(fromAdmin.city, 'munchen');

      final fromDistrict = HomeGeographyNormalizer.fromPlacemark(
        const HomeGeographyPlacemarkInput(
          isoCountryCode: 'TR',
          locality: '  ',
          administrativeArea: '',
          subAdministrativeArea: 'Kadıköy',
        ),
      );
      expect(fromDistrict!.country, 'TR');
      expect(fromDistrict.city, 'kadikoy');
    });

    test('missing country or city does not fabricate values', () {
      expect(
        HomeGeographyNormalizer.fromPlacemark(
          const HomeGeographyPlacemarkInput(
            isoCountryCode: null,
            locality: 'İstanbul',
          ),
        ),
        isNull,
      );
      expect(
        HomeGeographyNormalizer.fromPlacemark(
          const HomeGeographyPlacemarkInput(
            isoCountryCode: 'TUR',
            locality: 'İstanbul',
          ),
        ),
        isNull,
      );
      expect(
        HomeGeographyNormalizer.fromPlacemark(
          const HomeGeographyPlacemarkInput(
            isoCountryCode: 'TR',
            locality: null,
            administrativeArea: null,
            subAdministrativeArea: null,
          ),
        ),
        isNull,
      );
      expect(
        HomeGeographyNormalizer.fromPlacemark(
          const HomeGeographyPlacemarkInput(
            isoCountryCode: 'TR',
            locality: '???',
          ),
        ),
        isNull,
      );
      expect(HomeGeographyNormalizer.normalizeCountryCode(''), isNull);
      expect(HomeGeographyNormalizer.normalizeCountryCode('T'), isNull);
      expect(HomeGeographyNormalizer.normalizeCitySlug('   '), isNull);
    });
  });

  group('existing location fields', () {
    test(
        'toFirestore still writes location, location_text, distance_preference',
        () {
      const point = GeoPoint(41.0082, 28.9784);
      final profile = UserProfileModel(
        userId: 'u1',
        name: 'Ada',
        age: 28,
        gender: 'woman',
        location: point,
        locationText: 'Kadıköy, İstanbul',
        education: 'university',
        bio: 'hello',
        interests: const ['music'],
        lookingFor: 'relationship',
        ageRange: const [25, 35],
        distancePreference: 50,
      );
      final map = profile.toFirestore();
      expect(map['location'], point);
      expect(map['location_text'], 'Kadıköy, İstanbul');
      expect(map['distance_preference'], 50);
      expect(map.containsKey('home_country'), isFalse);
      expect(map.containsKey('home_city'), isFalse);
      expect(map.containsKey('home_geo_updated_at'), isFalse);
    });

    test(
        'location-share still builds location_text from placemark display fields',
        () {
      final src = File(
        'lib/features/profile/screens/steps/basic_info_step.dart',
      ).readAsStringSync();
      expect(
        src.contains(
          r"'${place.subAdministrativeArea ?? place.locality}, ${place.administrativeArea}'",
        ),
        isTrue,
      );
      expect(src.contains('HomeGeographyNormalizer.fromPlacemark'), isTrue);
      expect(src.contains('isoCountryCode: place.isoCountryCode'), isTrue);
      expect(src.contains('location_text'), isFalse);
    });
  });

  group('wiring', () {
    test('setup save passes derived home geography; photo save does not', () {
      final setup = File(
        'lib/features/profile/screens/profile_setup_screen.dart',
      ).readAsStringSync();
      expect(setup.contains('homeGeography: _homeGeography'), isTrue);
      expect(setup.contains('_homeGeography = home'), isTrue);

      final service = File(
        'lib/features/profile/services/profile_service.dart',
      ).readAsStringSync();
      expect(service.contains("payload['home_country']"), isTrue);
      expect(service.contains("payload['home_city']"), isTrue);
      expect(service.contains("payload['home_geo_updated_at']"), isTrue);
      expect(service.contains('if (homeGeography != null)'), isTrue);

      final photos = File(
        'lib/features/profile/screens/profile_photo_edit_screen.dart',
      ).readAsStringSync();
      expect(photos.contains('homeGeography:'), isFalse);
    });

    test('Discover Passport ON can add home city/country filter', () {
      final src = File(
        'lib/features/discover/services/discover_service.dart',
      ).readAsStringSync();
      expect(
          src.contains("where('discover_eligible', isEqualTo: true)"), isTrue);
      expect(src.contains("where('home_country'"), isTrue);
      expect(src.contains("where('home_city'"), isTrue);
      expect(src.contains('usesDestinationFilter'), isTrue);
      expect(src.contains('skipEligibleQuery'), isTrue);
    });
  });
}
