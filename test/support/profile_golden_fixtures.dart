import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qmatch/features/profile/models/user_profile_model.dart';

/// Synthetic Profile fixtures for goldens / widget tests. No Firebase I/O.
class ProfileGoldenFixtures {
  ProfileGoldenFixtures._();

  static const Size compactIphone = Size(375, 667);
  static const Size standardIphone = Size(390, 844);
  static const Size largeIphone = Size(430, 932);

  static Future<MemoryImage> syntheticPortraitProvider() async {
    const width = 240;
    const height = 240;
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
      const Offset(120, 100),
      48,
      Paint()..color = const Color(0x66E3C565),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return MemoryImage(Uint8List.view(bytes!.buffer));
  }

  static UserProfileModel full({
    String name = 'Ada',
    int age = 26,
    String? locationText = 'İstanbul',
    String bio = 'Quiet evenings, long walks, and good coffee.',
    List<String> interests = const ['Müzik', 'Seyahat', 'Bilim'],
    String? photoUrl = 'https://fixture.local/portrait.png',
    String gender = 'Kadın',
    String education = 'Lisans',
    String lookingFor = 'Ciddi İlişki',
  }) {
    return UserProfileModel(
      userId: 'fixture-profile-1',
      name: name,
      age: age,
      gender: gender,
      locationText: locationText,
      education: education,
      bio: bio,
      interests: interests,
      lookingFor: lookingFor,
      ageRange: const [25, 35],
      distancePreference: 50,
      profilePhotoUrl: photoUrl,
      // Legacy fields present but must not be rendered by Profile UI.
      archetype: 'Vizyon Lideri',
      category: 'HH',
    );
  }

  static UserProfileModel nameOnly() => full(
        name: 'Ada',
        age: 0,
        locationText: null,
        bio: '',
        interests: const [],
        photoUrl: null,
        gender: '',
        education: '',
        lookingFor: '',
      );

  static UserProfileModel missingPhoto() => full(photoUrl: null);

  static UserProfileModel missingBio() => full(bio: '');

  static UserProfileModel emptyInterests() => full(interests: const []);

  static UserProfileModel manyInterests() => full(
        interests: const [
          'Müzik',
          'Seyahat',
          'Bilim',
          'Sanat',
          'Yemek',
          'Doğa',
          'Kitap',
          'Sinema',
          'Spor',
          'Teknoloji',
        ],
      );

  static UserProfileModel longTurkishName() => full(
        name: 'Şule Ayşe Gökçehan',
        bio: 'Kısa bio.',
      );

  static UserProfileModel longCyrillicName() => full(
        name: 'Александра Николаевна',
        bio: 'Короткое описание.',
      );

  static UserProfileModel longBio() => full(
        bio: List.filled(
          12,
          'This is a long biography sentence used only for overflow and wrapping checks in goldens.',
        ).join(' '),
      );
}
