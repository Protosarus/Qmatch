import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/features/messages/utils/qmatch_chat_wallpaper_assets.dart';

import 'support/chat_detail_golden_fixtures.dart';
import 'support/chat_detail_golden_scene.dart';

/// Deterministic chat-detail goldens (P2C-1C-3B). Synthetic fixtures only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryImage portrait;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    portrait = await _syntheticPortrait();
  });

  Future<void> pumpScene(
    WidgetTester tester, {
    required ChatDetailGoldenScene scene,
    required Size size,
    double textScale = 1.0,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrapChatDetailGolden(
        surfaceSize: size,
        textScale: textScale,
        viewInsets: viewInsets,
        child: TickerMode(enabled: false, child: scene),
      ),
    );
    // Precache wallpaper so the first golden (empty) is not captured before
    // the asset decode completes — later scenes were warm-cached previously.
    final BuildContext ctx = tester.element(find.byType(MaterialApp));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage(QMatchChatWallpaperAssets.runtimePrimary),
        ctx,
      );
      await precacheImage(
        const AssetImage(QMatchChatWallpaperAssets.sourcePng),
        ctx,
      );
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  }

  Future<void> expectGolden(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/chat_detail/$name.png'),
    );
  }

  testWidgets('empty compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      scene: const ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.empty,
      ),
    );
    expect(find.byKey(const Key('qmatch-chat-empty')), findsOneWidget);
    expect(
        find.byKey(const Key('qmatch-chat-wallpaper-image')), findsOneWidget);
    await expectGolden(tester, 'empty_compact_1_0');
  });

  testWidgets('loading compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      scene: const ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.loading,
      ),
    );
    expect(find.byKey(const Key('qmatch-chat-loading')), findsOneWidget);
    await expectGolden(tester, 'loading_compact_1_0');
  });

  testWidgets('error compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      scene: const ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.error,
      ),
    );
    expect(find.byKey(const Key('qmatch-chat-error')), findsOneWidget);
    await expectGolden(tester, 'error_compact_1_0');
  });

  testWidgets('incoming compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      scene: ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.incoming,
        counterpartPhotoProvider: portrait,
      ),
    );
    expect(find.byKey(const Key('qmatch-chat-bubble-in')), findsOneWidget);
    await expectGolden(tester, 'incoming_compact_1_0');
  });

  testWidgets('outgoing compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      scene: ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.outgoing,
        counterpartPhotoProvider: portrait,
      ),
    );
    expect(find.byKey(const Key('qmatch-chat-bubble-out')), findsOneWidget);
    await expectGolden(tester, 'outgoing_compact_1_0');
  });

  testWidgets('mixed conversation compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      scene: ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.mixed,
        counterpartPhotoProvider: portrait,
      ),
    );
    expect(find.byKey(const Key('qmatch-chat-date-separator')), findsWidgets);
    await expectGolden(tester, 'mixed_compact_1_0');
  });

  testWidgets('long message compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      scene: const ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.longMessage,
      ),
    );
    await expectGolden(tester, 'long_message_compact_1_0');
  });

  testWidgets('emoji multiline compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      scene: const ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.emojiMultiline,
      ),
    );
    await expectGolden(tester, 'emoji_multiline_compact_1_0');
  });

  testWidgets('missing counterpart compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      scene: const ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.missingCounterpart,
        counterpartName: '',
      ),
    );
    expect(find.text('Conversation'), findsOneWidget);
    expect(
      find.byKey(const Key('qmatch-conversation-avatar-missing')),
      findsOneWidget,
    );
    await expectGolden(tester, 'missing_counterpart_compact_1_0');
  });

  testWidgets('composer keyboard insets compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      viewInsets: const EdgeInsets.only(bottom: 280),
      scene: const ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.composerFocus,
        composerText: 'Hello keyboard',
      ),
    );
    await expectGolden(tester, 'composer_keyboard_compact_1_0');
  });

  testWidgets('mixed large 1.0', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.largeIphone,
      scene: ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.mixed,
        counterpartPhotoProvider: portrait,
      ),
    );
    await expectGolden(tester, 'mixed_large_1_0');
  });

  testWidgets('mixed compact textScale 1.3', (tester) async {
    await pumpScene(
      tester,
      size: ChatDetailGoldenFixtures.compactIphone,
      textScale: 1.3,
      scene: ChatDetailGoldenScene(
        variant: ChatDetailGoldenVariant.mixed,
        counterpartPhotoProvider: portrait,
      ),
    );
    await expectGolden(tester, 'mixed_compact_text_1_3');
  });
}

Future<MemoryImage> _syntheticPortrait() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = const Color(0xFF7C6CFF);
  canvas.drawCircle(const Offset(32, 32), 30, paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 64);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return MemoryImage(Uint8List.view(bytes!.buffer));
}
