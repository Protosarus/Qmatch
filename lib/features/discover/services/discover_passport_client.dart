import 'package:cloud_functions/cloud_functions.dart';

import '../../profile/domain/home_geography.dart';
import '../domain/discover_passport_snapshot.dart';

/// Free users cannot activate Passport. Backend remains authority.
class DiscoverPassportResonanceRequiredException implements Exception {
  const DiscoverPassportResonanceRequiredException();
}

/// Client for trusted Discover Passport callables.
///
/// Snapshot is UX only. Discover filtering uses [get] at query time.
/// Does not write `location`, `home_*`, geohash, or L2 payloads.
class DiscoverPassportClient {
  DiscoverPassportClient({
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    )? call,
    Future<DiscoverPassportSnapshot> Function()? getOverride,
    Future<DiscoverPassportSnapshot> Function(
      String country,
      String city,
    )? setOverride,
    Future<DiscoverPassportSnapshot> Function()? disableOverride,
  })  : _functions = functions,
        _call = call,
        _getOverride = getOverride,
        _setOverride = setOverride,
        _disableOverride = disableOverride;

  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? _call;
  final Future<DiscoverPassportSnapshot> Function()? _getOverride;
  final Future<DiscoverPassportSnapshot> Function(String country, String city)?
      _setOverride;
  final Future<DiscoverPassportSnapshot> Function()? _disableOverride;

  // Legacy callable contract — kept for compatibility and test injection.
  static const String getCallableName = 'getDiscoverPassport';
  static const String setCallableName = 'setDiscoverPassport';
  static const String disableCallableName = 'disableDiscoverPassport';

  // Current production endpoints, colocated with Firestore.
  static const String getCallableNameEu = 'getDiscoverPassportEu';
  static const String setCallableNameEu = 'setDiscoverPassportEu';
  static const String disableCallableNameEu = 'disableDiscoverPassportEu';
  static const String callableRegionEu = 'europe-west1';

  /// In-memory UX copy. Never used as Discover query authority.
  DiscoverPassportSnapshot uxSnapshot = DiscoverPassportSnapshot.worldwide;

  Future<DiscoverPassportSnapshot> get() async {
    final custom = _getOverride;
    if (custom != null) {
      uxSnapshot = await custom();
      return uxSnapshot;
    }
    uxSnapshot = DiscoverPassportSnapshot.fromTrustedMap(
      await _invoke(getCallableName, const {}),
    );
    return uxSnapshot;
  }

  Future<DiscoverPassportSnapshot> set({
    required String country,
    required String city,
  }) async {
    final countryCode = HomeGeographyNormalizer.normalizeCountryCode(country);
    final citySlug = HomeGeographyNormalizer.normalizeCitySlug(city);
    if (countryCode == null || citySlug == null) {
      throw ArgumentError(
          'Passport destination must be ISO country + city slug.');
    }
    final custom = _setOverride;
    if (custom != null) {
      uxSnapshot = await custom(countryCode, citySlug);
      return uxSnapshot;
    }
    try {
      uxSnapshot = DiscoverPassportSnapshot.fromTrustedMap(
        await _invoke(setCallableName, {
          'passport_country': countryCode,
          'passport_city': citySlug,
        }),
      );
      return uxSnapshot;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        throw const DiscoverPassportResonanceRequiredException();
      }
      rethrow;
    }
  }

  Future<DiscoverPassportSnapshot> disable() async {
    final custom = _disableOverride;
    if (custom != null) {
      uxSnapshot = await custom();
      return uxSnapshot;
    }
    uxSnapshot = DiscoverPassportSnapshot.fromTrustedMap(
      await _invoke(disableCallableName, const {}),
    );
    return uxSnapshot;
  }

  Future<Map<String, dynamic>> _invoke(
    String name,
    Map<String, dynamic> data,
  ) async {
    final custom = _call;
    if (custom != null) return custom(name, data);

    final productionName = switch (name) {
      getCallableName => getCallableNameEu,
      setCallableName => setCallableNameEu,
      disableCallableName => disableCallableNameEu,
      _ => name,
    };

    final functions = _functions ??
        FirebaseFunctions.instanceFor(
          region: callableRegionEu,
        );

    try {
      final result = await functions.httpsCallable(productionName).call(data);
      final payload = result.data;
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      throw StateError('Callable $name returned a non-map payload.');
    } on FirebaseFunctionsException catch (e) {
      if (name == setCallableName && e.code == 'failed-precondition') {
        throw const DiscoverPassportResonanceRequiredException();
      }
      rethrow;
    }
  }
}
