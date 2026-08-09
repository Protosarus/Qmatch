import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qmatch/features/discover/models/discover_user_model.dart';

/// Test-only synthetic Discover fixtures. No Firebase I/O.
class DiscoverGoldenFixtures {
  DiscoverGoldenFixtures._();

  static const Size compactIphone = Size(375, 667);
  static const Size largeIphone = Size(430, 932);

  /// Deterministic violet portrait placeholder (no network).
  static Future<MemoryImage> syntheticPortraitProvider() async {
    const width = 240;
    const height = 320;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2A2458),
          Color(0xFF5B4B8A),
          Color(0xFF161B3A),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    canvas.drawCircle(
      const Offset(120, 110),
      42,
      Paint()..color = const Color(0x66E3C565),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return MemoryImage(Uint8List.view(bytes!.buffer));
  }

  static DiscoverUserModel candidateWithLegacyCompat({
    required String name,
    required int age,
    String bio = 'Enjoys quiet evenings and long walks.',
    List<String> interests = const ['music', 'travel'],
    String? profilePhotoUrl = 'https://fixture.local/portrait.png',
  }) {
    return DiscoverUserModel(
      uid: 'fixture-candidate-1',
      name: name,
      age: age,
      bio: bio,
      interests: interests,
      profilePhotoUrl: profilePhotoUrl,
      // Legacy CompatibilityScoring / archetype fields — temporary UI only.
      compatibilityScore: 0.82,
      compatibilityLabel: 'strong',
      compatibilityReasons: const ['thinking', 'emotional', 'interests'],
      // Leave archetype/category null in goldens to avoid unknown-id noise;
      // legacy chips for label/score/reasons remain intentional (G-041).
    );
  }

  static DiscoverUserModel candidateMissingPhoto() {
    return candidateWithLegacyCompat(
      name: 'No Photo',
      age: 28,
      profilePhotoUrl: null,
    ).copyWith(photos: const []);
  }

  static DiscoverUserModel candidateLongContent() {
    return candidateWithLegacyCompat(
      name:
          'Very Long Display Name That Should Ellipsize Gracefully Across Compact Viewports',
      age: 31,
      bio: List.filled(
        24,
        'This is a long bio sentence used only for golden overflow checks.',
      ).join(' '),
      interests: const [
        'music',
        'travel',
        'science',
        'art',
        'cooking',
        'hiking',
      ],
      profilePhotoUrl: null,
    );
  }

  static DiscoverUserModel candidateWithoutLegacyCompat() {
    return const DiscoverUserModel(
      uid: 'fixture-candidate-clean',
      name: 'Clean Profile',
      age: 27,
      bio: 'No legacy compatibility chips on this fixture.',
      interests: ['reading'],
    );
  }
}
