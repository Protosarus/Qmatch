import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/firebase_options.dart';

/// Active Android Firebase identity must match canonical `com.qmatch.app`.
void main() {
  const canonicalAndroidAppId =
      '1:55490039374:android:ac78c8796ce0ef06c7fd1f';
  const staleAndroidAppId = '1:55490039374:android:5c9fd0918fe15626c7fd1f';
  const canonicalPackage = 'com.qmatch.app';
  const stalePackage = 'com.example.qmatch';
  const canonicalIosAppId = '1:55490039374:ios:523d1a173f0ba32ac7fd1f';

  test('FlutterFire Android options use canonical Firebase appId', () {
    expect(DefaultFirebaseOptions.android.appId, canonicalAndroidAppId);
    expect(DefaultFirebaseOptions.android.projectId, 'qmatch-53d62');
    expect(DefaultFirebaseOptions.android.appId, isNot(staleAndroidAppId));
  });

  test('iOS FlutterFire options remain unchanged', () {
    expect(DefaultFirebaseOptions.ios.appId, canonicalIosAppId);
    expect(DefaultFirebaseOptions.ios.iosBundleId, canonicalPackage);
    expect(DefaultFirebaseOptions.ios.projectId, 'qmatch-53d62');
  });

  test('firebase.json FlutterFire Android appId is canonical', () {
    final json = jsonDecode(File('firebase.json').readAsStringSync())
        as Map<String, dynamic>;
    final flutter = json['flutter'] as Map<String, dynamic>;
    final platforms = flutter['platforms'] as Map<String, dynamic>;
    final androidDefault =
        (platforms['android'] as Map)['default'] as Map<String, dynamic>;
    final dartConfigs =
        ((platforms['dart'] as Map)['lib/firebase_options.dart']
                as Map)['configurations']
            as Map<String, dynamic>;

    expect(androidDefault['appId'], canonicalAndroidAppId);
    expect(androidDefault['projectId'], 'qmatch-53d62');
    expect(dartConfigs['android'], canonicalAndroidAppId);
    expect(dartConfigs['ios'], canonicalIosAppId);
  });

  test('google-services.json only ships canonical com.qmatch.app client', () {
    final json = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(json['project_info']['project_id'], 'qmatch-53d62');

    final clients = json['client'] as List<dynamic>;
    expect(clients, hasLength(1));

    final client = clients.single as Map<String, dynamic>;
    final info = client['client_info'] as Map<String, dynamic>;
    final androidInfo = info['android_client_info'] as Map<String, dynamic>;

    expect(info['mobilesdk_app_id'], canonicalAndroidAppId);
    expect(androidInfo['package_name'], canonicalPackage);

    final raw = File('android/app/google-services.json').readAsStringSync();
    expect(raw.contains(stalePackage), isFalse);
    expect(raw.contains(staleAndroidAppId), isFalse);
  });

  test('Gradle applicationId/namespace stay com.qmatch.app', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle.contains('applicationId = "$canonicalPackage"'), isTrue);
    expect(gradle.contains('namespace = "$canonicalPackage"'), isTrue);
    expect(gradle.contains(stalePackage), isFalse);
  });

  test('active Android runtime configs do not reference com.example.qmatch', () {
    for (final path in [
      'lib/firebase_options.dart',
      'firebase.json',
      'android/app/google-services.json',
      'android/app/build.gradle.kts',
    ]) {
      final text = File(path).readAsStringSync();
      expect(text.contains(stalePackage), isFalse, reason: path);
      expect(text.contains(staleAndroidAppId), isFalse, reason: path);
    }
  });

  test('PLAY_IAP_PACKAGE_NAME expectation remains com.qmatch.app', () {
    final binding = File(
      'functions/test/store_iap_secrets_binding_v1.test.js',
    ).readAsStringSync();
    expect(binding.contains("PLAY_IAP_PACKAGE_NAME: 'com.qmatch.app'"), isTrue);

    final playClients =
        File('functions/src/play_iap_clients.js').readAsStringSync();
    expect(playClients.contains("'com.qmatch.app'"), isTrue);
  });
}
