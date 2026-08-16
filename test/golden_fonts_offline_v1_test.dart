import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;

/// Offline stand-ins under [test/fonts/google_fonts/] required by golden-tested UI.
const _requiredGoldenFontAssets = <String>[
  'Inter-Regular.ttf',
  'Inter-Medium.ttf',
  'Inter-SemiBold.ttf',
  'Inter-Bold.ttf',
  'Inter-Italic.ttf',
  'PlayfairDisplay-Regular.ttf',
  'PlayfairDisplay-SemiBold.ttf',
  'PlayfairDisplay-Bold.ttf',
  'PlayfairDisplay-MediumItalic.ttf',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    google_fonts_base.clearCache();
    google_fonts_base.assetManifest = null;
  });

  testWidgets('golden font assets are bundled for offline google_fonts lookup',
      (tester) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();

    for (final name in _requiredGoldenFontAssets) {
      expect(
        assets.any((asset) => asset.endsWith(name)),
        isTrue,
        reason: '$name must be listed under pubspec assets '
            '(test/fonts/google_fonts/)',
      );
    }
  });

  testWidgets(
      'Playfair/Inter golden variants load without runtime fetch',
      (tester) async {
    final loadErrors = <String>[];

    await runZoned(
      () async {
        // Trigger the exact variants golden-tested live UI requests.
        final styles = <TextStyle>[
          GoogleFonts.inter(),
          GoogleFonts.inter(fontWeight: FontWeight.w500),
          GoogleFonts.inter(fontWeight: FontWeight.w600),
          GoogleFonts.inter(fontWeight: FontWeight.w700),
          GoogleFonts.inter(fontStyle: FontStyle.italic),
          GoogleFonts.playfairDisplay(),
          GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
          GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
          GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  for (final style in styles) Text('Aa', style: style),
                ],
              ),
            ),
          ),
        );

        await Future.wait(google_fonts_base.pendingFontFutures.toList());
        await tester.pump();
      },
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          if (line.contains('google_fonts was unable to load font')) {
            loadErrors.add(line);
          }
          parent.print(zone, line);
        },
      ),
    );

    expect(
      loadErrors,
      isEmpty,
      reason: 'Missing offline stand-ins under test/fonts/google_fonts/',
    );
  });
}
