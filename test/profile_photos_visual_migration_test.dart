import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/core/widgets/qmatch_primary_action.dart';
import 'package:qmatch/core/widgets/qmatch_pushed_screen_header.dart';
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

  UserProfileModel base({List<String> photos = const []}) {
    return UserProfileModel(
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
  }

  Future<void> pumpPhotos(
    WidgetTester tester, {
    required Widget home,
    Size size = const Size(390, 844),
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
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
          ),
          child: home,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('zero photos: empty state, no nine placeholders', (tester) async {
    await pumpPhotos(
      tester,
      home: ProfilePhotoEditScreen(
        profile: base(),
        debugPhotos: const [],
        animateBackground: false,
      ),
    );
    expect(find.byKey(const Key('qmatch-photos-empty')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-photos-grid')), findsNothing);
    expect(find.byKey(const Key('qmatch-photos-add-button')), findsOneWidget);
    expect(find.byType(QMatchPushedScreenHeader), findsOneWidget);
    expect(find.byType(QMatchPrimaryAction), findsOneWidget);
    expect(find.textContaining('0/9'), findsOneWidget);
  });

  testWidgets('one photo + add tile', (tester) async {
    await pumpPhotos(
      tester,
      home: ProfilePhotoEditScreen(
        profile: base(photos: const ['https://fixture.local/1.png']),
        debugPhotos: const ['https://fixture.local/1.png'],
        animateBackground: false,
        photoImageProviders: {0: portrait},
      ),
    );
    expect(find.byKey(const Key('qmatch-photo-tile-0')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-photos-add-tile')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-photos-empty')), findsNothing);
  });

  testWidgets('eight photos + add tile', (tester) async {
    final urls = List.generate(8, (i) => 'https://fixture.local/$i.png');
    await pumpPhotos(
      tester,
      home: ProfilePhotoEditScreen(
        profile: base(photos: urls),
        debugPhotos: urls,
        animateBackground: false,
        photoImageProviders: {
          for (var i = 0; i < 8; i++) i: portrait,
        },
      ),
    );
    expect(find.byKey(const Key('qmatch-photos-add-tile')), findsOneWidget);
    expect(find.byKey(const Key('qmatch-photo-tile-7')), findsOneWidget);
  });

  testWidgets('nine photos: no add tile; max unchanged', (tester) async {
    final urls = List.generate(9, (i) => 'https://fixture.local/$i.png');
    await pumpPhotos(
      tester,
      home: ProfilePhotoEditScreen(
        profile: base(photos: urls),
        debugPhotos: urls,
        animateBackground: false,
        photoImageProviders: {
          for (var i = 0; i < 9; i++) i: portrait,
        },
      ),
    );
    expect(find.byKey(const Key('qmatch-photos-add-tile')), findsNothing);
    expect(find.byKey(const Key('qmatch-photos-add-button')), findsNothing);
    expect(kProfilePhotoMaxCount, 9);
    expect(find.textContaining('9/9'), findsOneWidget);
  });

  testWidgets('uploading disables add button label', (tester) async {
    await pumpPhotos(
      tester,
      home: ProfilePhotoEditScreen(
        profile: base(photos: const ['https://fixture.local/1.png']),
        debugPhotos: const ['https://fixture.local/1.png'],
        debugUploading: true,
        animateBackground: false,
        photoImageProviders: {0: portrait},
      ),
    );
    expect(find.byType(QMatchPrimaryAction), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('shared header is used and legacy gold button is gone',
      (tester) async {
    await pumpPhotos(
      tester,
      home: ProfilePhotoEditScreen(
        profile: base(),
        debugPhotos: const [],
        animateBackground: false,
      ),
    );
    expect(find.byType(QMatchPushedScreenHeader), findsOneWidget);
    expect(find.byType(QMatchPrimaryAction), findsOneWidget);
    expect(find.text('ADD PHOTOS'), findsNothing);
  });

  testWidgets(
      'add photo callback remains wired and duplicate taps are prevented',
      (tester) async {
    var pickCalls = 0;
    var saveCalls = 0;
    UserProfileModel? lastProfile;

    await pumpPhotos(
      tester,
      home: ProfilePhotoEditScreen(
        profile: base(),
        debugPhotos: const [],
        animateBackground: false,
        debugPickPhotos: (maxImages) async {
          pickCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return ['https://fixture.local/new.png'];
        },
        debugSaveProfile: (profile) async {
          saveCalls++;
          lastProfile = profile;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('qmatch-photos-add-button')));
    await tester.tap(find.byKey(const Key('qmatch-photos-add-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(pickCalls, 1);
    expect(saveCalls, 1);
    expect(lastProfile?.photos.length, 1);
  });

  test('no new Storage or Firestore path introduced in photo screen', () {
    final screen =
        File('lib/features/profile/screens/profile_photo_edit_screen.dart')
            .readAsStringSync();
    expect(screen, isNot(contains('profile_photos/')));
    expect(screen, isNot(contains("collection('users')")));
    expect(screen, contains('debugPickPhotos'));
    expect(screen, contains('debugSaveProfile'));
  });

  testWidgets('compact + textScale 1.3', (tester) async {
    await pumpPhotos(
      tester,
      size: const Size(375, 667),
      textScale: 1.3,
      home: ProfilePhotoEditScreen(
        profile: base(),
        debugPhotos: const [],
        animateBackground: false,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<MemoryImage> _portrait() async {
  const w = 120;
  const h = 120;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF5B4B8A),
  );
  final img = await recorder.endRecording().toImage(w, h);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return MemoryImage(Uint8List.view(bytes!.buffer));
}
