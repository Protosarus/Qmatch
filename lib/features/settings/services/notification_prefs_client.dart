import 'package:cloud_functions/cloud_functions.dart';

import '../domain/notification_prefs_snapshot.dart';

/// Client for trusted notification preference callables (europe-west1).
///
/// Missing server docs resolve to all-enabled. Never uses SharedPreferences.
class NotificationPrefsClient {
  NotificationPrefsClient({
    FirebaseFunctions? functions,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    )? call,
  })  : _functions = functions,
        _call = call;

  final FirebaseFunctions? _functions;
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? _call;

  static const String region = 'europe-west1';
  static const String getCallableName = 'getNotificationPrefs';
  static const String setCallableName = 'setNotificationPrefs';

  Future<NotificationPrefsSnapshot> get() async {
    return NotificationPrefsSnapshot.fromTrustedMap(
      await _invoke(getCallableName, const {}),
    );
  }

  Future<NotificationPrefsSnapshot> set(NotificationPrefsSnapshot prefs) async {
    return NotificationPrefsSnapshot.fromTrustedMap(
      await _invoke(setCallableName, prefs.toCallablePayload()),
    );
  }

  Future<Map<String, dynamic>> _invoke(
    String name,
    Map<String, dynamic> data,
  ) async {
    final custom = _call;
    if (custom != null) return custom(name, data);
    final functions =
        _functions ?? FirebaseFunctions.instanceFor(region: region);
    final result = await functions.httpsCallable(name).call(data);
    final payload = result.data;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Callable $name returned a non-map payload.');
  }
}
