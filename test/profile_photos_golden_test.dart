import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/profile/models/user_profile_model.dart';
import 'package:qmatch/features/profile/screens/profile_photo_edit_screen.dart';
import 'package:qmatch/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryImage portrait;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    portrait = await _portrait();
  });

  UserProfileModel base(List<String> photos) => UserProfileModel(
        userId: 'u1',
        name: 'Ada',
        age: 26,
        gender: 'Kadın',
        education: 'Lisans',
        bio: 'Bio',
        interests: const [],
        lookingFor: 'Ciddi İlişki',
        ageRange: const [25, 35],
        distancePreference: 50,
        photos: photos,
        profilePhotoUrl: photos.isNotEmpty ? photos.first : null,
      );

  Future<void> pump(
    WidgetTester tester, {
    required Widget child,
    Size size = const Size(375, 667),
    double textScale = 1.0,
    Locale locale = const Locale('en'),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.cosmicBlack,
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(bottom: 34),
            textScaler: TextScaler.linear(textScale),
            devicePixelRatio: 1,
          ),
          child: child,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  Future<void> expectGolden(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/profile_photos/$name.png'),
    );
  }

  testWidgets('zero photos', (tester) async {
    await pump(
      tester,
      child: ProfilePhotoEditScreen(
        profile: base(const []),
        debugPhotos: const [],
        animateBackground: false,
      ),
    );
    await expectGolden(tester, 'zero_compact_1_0');
  });

  testWidgets('one photo', (tester) async {
    await pump(
      tester,
      child: ProfilePhotoEditScreen(
        profile: base(const ['https://f.local/1.png']),
        debugPhotos: const ['https://f.local/1.png'],
        animateBackground: false,
        photoImageProviders: {0: portrait},
      ),
    );
    await expectGolden(tester, 'one_compact_1_0');
  });

  testWidgets('eight photos', (tester) async {
    final urls = List.generate(8, (i) => 'https://f.local/$i.png');
    await pump(
      tester,
      child: ProfilePhotoEditScreen(
        profile: base(urls),
        debugPhotos: urls,
        animateBackground: false,
        photoImageProviders: {for (var i = 0; i < 8; i++) i: portrait},
      ),
    );
    await expectGolden(tester, 'eight_compact_1_0');
  });

  testWidgets('nine photos', (tester) async {
    final urls = List.generate(9, (i) => 'https://f.local/$i.png');
    await pump(
      tester,
      child: ProfilePhotoEditScreen(
        profile: base(urls),
        debugPhotos: urls,
        animateBackground: false,
        photoImageProviders: {for (var i = 0; i < 9; i++) i: portrait},
      ),
    );
    await expectGolden(tester, 'nine_compact_1_0');
  });

  testWidgets('uploading', (tester) async {
    await pump(
      tester,
      child: ProfilePhotoEditScreen(
        profile: base(const ['https://f.local/1.png']),
        debugPhotos: const ['https://f.local/1.png'],
        debugUploading: true,
        animateBackground: false,
        photoImageProviders: {0: portrait},
      ),
    );
    await expectGolden(tester, 'uploading_compact_1_0');
  });

  testWidgets('zero photos Turkish', (tester) async {
    await pump(
      tester,
      locale: const Locale('tr'),
      child: ProfilePhotoEditScreen(
        profile: base(const []),
        debugPhotos: const [],
        animateBackground: false,
      ),
    );
    await expectGolden(tester, 'zero_tr_compact_1_0');
  });

  testWidgets('textScale 1.3', (tester) async {
    await pump(
      tester,
      textScale: 1.3,
      child: ProfilePhotoEditScreen(
        profile: base(const []),
        debugPhotos: const [],
        animateBackground: false,
      ),
    );
    await expectGolden(tester, 'zero_compact_1_3');
  });
}

Future<MemoryImage> _portrait() async {
  const w = 120;
  const h = 120;
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF5B4B8A),
  );
  final img = await recorder.endRecording().toImage(w, h);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return MemoryImage(Uint8List.view(bytes!.buffer));
}
