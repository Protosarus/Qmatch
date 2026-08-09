import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'support/messages_golden_fixtures.dart';
import 'support/messages_golden_scene.dart';

/// Deterministic Messages inbox goldens (P2C-1C-3A). Synthetic fixtures only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryImage portrait;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    portrait = await _syntheticPortrait();
  });

  Future<void> pumpScene(
    WidgetTester tester, {
    required MessagesGoldenScene scene,
    required Size size,
    double textScale = 1.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      wrapMessagesGolden(
        surfaceSize: size,
        textScale: textScale,
        child: TickerMode(enabled: false, child: scene),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  }

  Future<void> expectGolden(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/messages/$name.png'),
    );
  }

  testWidgets('loading compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: const MessagesGoldenScene(variant: MessagesGoldenVariant.loading),
    );
    expect(find.byKey(const Key('qmatch-messages-loading')), findsOneWidget);
    await expectGolden(tester, 'loading_compact_1_0');
  });

  testWidgets('empty compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: const MessagesGoldenScene(variant: MessagesGoldenVariant.empty),
    );
    expect(find.byKey(const Key('qmatch-messages-empty')), findsOneWidget);
    await expectGolden(tester, 'empty_compact_1_0');
  });

  testWidgets('error compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: const MessagesGoldenScene(variant: MessagesGoldenVariant.error),
    );
    expect(find.byKey(const Key('qmatch-messages-error')), findsOneWidget);
    await expectGolden(tester, 'error_compact_1_0');
  });

  testWidgets('read conversation compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: MessagesGoldenScene(
        variant: MessagesGoldenVariant.list,
        conversations: [
          MessagesConversationFixture(
            displayName: 'Ada',
            age: 30,
            previewText: 'Looking forward to chatting.',
            timestampText: '14:22',
            unreadCount: 0,
            photoImageProvider: portrait,
          ),
        ],
      ),
    );
    expect(find.byKey(const Key('qmatch-conversation-unread')), findsNothing);
    await expectGolden(tester, 'read_conversation_compact_1_0');
  });

  testWidgets('unread conversation compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: MessagesGoldenScene(
        variant: MessagesGoldenVariant.list,
        conversations: [
          MessagesConversationFixture(
            displayName: 'Grace',
            age: 28,
            previewText: 'Are you free this weekend?',
            timestampText: '09:10',
            unreadCount: 2,
            photoImageProvider: portrait,
          ),
        ],
      ),
    );
    expect(find.byKey(const Key('qmatch-conversation-unread')), findsOneWidget);
    await expectGolden(tester, 'unread_conversation_compact_1_0');
  });

  testWidgets('multiple conversations compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: MessagesGoldenScene(
        variant: MessagesGoldenVariant.list,
        conversations: [
          MessagesConversationFixture(
            displayName: 'Ada',
            age: 30,
            previewText: 'Unread latest',
            timestampText: '15:01',
            unreadCount: 3,
            photoImageProvider: portrait,
          ),
          MessagesConversationFixture(
            displayName: 'Grace',
            age: 28,
            previewText: 'Read earlier',
            timestampText: '20.07',
            unreadCount: 0,
            photoImageProvider: portrait,
          ),
          const MessagesConversationFixture(
            displayName: 'Conversation',
            previewText: 'Say hi',
            timestampText: '18.07',
            unreadCount: 0,
          ),
        ],
      ),
    );
    await expectGolden(tester, 'multiple_conversations_compact_1_0');
  });

  testWidgets('missing avatar compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: const MessagesGoldenScene(
        variant: MessagesGoldenVariant.list,
        conversations: [
          MessagesConversationFixture(
            displayName: 'No Photo',
            age: 27,
            previewText: 'Hello',
            timestampText: '11:00',
          ),
        ],
      ),
    );
    expect(
      find.byKey(const Key('qmatch-conversation-avatar-missing')),
      findsOneWidget,
    );
    await expectGolden(tester, 'missing_avatar_compact_1_0');
  });

  testWidgets('deleted counterpart compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: const MessagesGoldenScene(
        variant: MessagesGoldenVariant.list,
        conversations: [
          MessagesConversationFixture(
            displayName: 'Conversation',
            previewText: 'Say hi',
            timestampText: '10:00',
          ),
        ],
      ),
    );
    expect(find.text('Conversation'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
    await expectGolden(tester, 'deleted_counterpart_compact_1_0');
  });

  testWidgets('long name and preview compact 1.0', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: MessagesGoldenScene(
        variant: MessagesGoldenVariant.list,
        conversations: [
          MessagesConversationFixture(
            displayName:
                'Very Long Display Name That Should Ellipsize Across Compact Viewports',
            age: 31,
            previewText: List.filled(
              18,
              'Long preview sentence used for overflow checks.',
            ).join(' '),
            timestampText: '16:40',
            unreadCount: 1,
            photoImageProvider: portrait,
          ),
        ],
      ),
    );
    await expectGolden(tester, 'long_content_compact_1_0');
  });

  testWidgets('list text scale 1.3 compact', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      textScale: 1.3,
      scene: MessagesGoldenScene(
        variant: MessagesGoldenVariant.list,
        conversations: [
          MessagesConversationFixture(
            displayName: 'Ada',
            age: 30,
            previewText: 'Scaled text check',
            timestampText: '14:00',
            unreadCount: 1,
            photoImageProvider: portrait,
          ),
        ],
      ),
    );
    await expectGolden(tester, 'list_compact_1_3');
  });

  testWidgets('shell list clears bottom nav', (tester) async {
    await pumpScene(
      tester,
      size: MessagesGoldenFixtures.compactIphone,
      scene: MessagesGoldenScene(
        variant: MessagesGoldenVariant.list,
        includeShell: true,
        conversations: [
          MessagesConversationFixture(
            displayName: 'Ada',
            age: 30,
            previewText: 'Nav clearance',
            timestampText: '12:00',
            photoImageProvider: portrait,
          ),
        ],
      ),
    );
    final tile =
        tester.getRect(find.byKey(const Key('qmatch-conversation-tile')));
    final nav = tester.getRect(
      find.byKey(const Key('qmatch-bottom-navigation')),
    );
    expect(tile.bottom <= nav.top + 0.5, isTrue);
    await expectGolden(tester, 'shell_list_nav_clearance_compact_1_0');
  });
}

Future<MemoryImage> _syntheticPortrait() async {
  const width = 96;
  const height = 96;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2A2458), Color(0xFF5B4B8A)],
      ).createShader(rect),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return MemoryImage(Uint8List.view(bytes!.buffer));
}
