import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/messages/models/message_model.dart';
import 'package:qmatch/features/messages/utils/chat_message_timestamp_format.dart';
import 'package:qmatch/features/messages/utils/qmatch_chat_wallpaper_assets.dart';
import 'package:qmatch/features/messages/widgets/chat_detail_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';

import 'support/chat_detail_golden_fixtures.dart';
import 'support/chat_detail_golden_scene.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('chat wallpaper assets', () {
    test('repository-owned background assets exist', () {
      expect(
        File('assets/images/chat/qmatch_chat_pattern_source.png').existsSync(),
        isTrue,
      );
      expect(
        File('assets/images/chat/qmatch_chat_pattern.webp').existsSync(),
        isTrue,
      );
    });

    test('runtime constants are ASCII repo paths', () {
      expect(
        QMatchChatWallpaperAssets.runtimePrimary,
        'assets/images/chat/qmatch_chat_pattern.webp',
      );
      expect(
        QMatchChatWallpaperAssets.sourcePng,
        'assets/images/chat/qmatch_chat_pattern_source.png',
      );
      expect(
        QMatchChatWallpaperAssets.runtimePrimary.contains('Downloads'),
        isFalse,
      );
    });

    test('no production code references user Downloads wallpaper path', () {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in dartFiles) {
        final src = f.readAsStringSync();
        expect(
          src.contains('/Downloads/'),
          isFalse,
          reason: '${f.path} must not reference Downloads path',
        );
        expect(
          src.contains('uzay çizimleri') || src.contains('uzay cizimleri'),
          isFalse,
          reason: '${f.path} must not reference Downloads wallpaper filename',
        );
      }
      expect(
        QMatchChatWallpaperAssets.runtimePrimary.startsWith('assets/'),
        isTrue,
      );
    });

    test('ChatService source remains unchanged in this phase', () {
      final svc = File('lib/features/messages/services/chat_service.dart');
      expect(svc.existsSync(), isTrue);
      final src = svc.readAsStringSync();
      expect(src.contains('getMessagesStream'), isTrue);
      expect(src.contains('sendTextMessage'), isTrue);
      expect(src.contains('markThreadAsRead'), isTrue);
    });

    test('background asset is not uploaded via Firebase Storage helpers', () {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in dartFiles) {
        final src = f.readAsStringSync();
        if (src.contains('qmatch_chat_pattern')) {
          expect(
            src.contains('FirebaseStorage') || src.contains('putFile'),
            isFalse,
            reason: '${f.path} must not upload wallpaper',
          );
        }
      }
    });
  });

  group('timestamp / date separators', () {
    test('pending/null timestamp is safe', () {
      final m = MessageModel(
        messageId: '1',
        threadId: 't',
        senderId: 'a',
        type: MessageType.text,
        text: 'hi',
      );
      expect(formatChatMessageTime(m), isNull);
      expect(messageLocalDay(m), isNull);
      expect(shouldShowChatDateSeparator([m], 0), isFalse);
    });

    test('date separator appears on day boundary', () {
      final a = ChatDetailGoldenFixtures.textMessage(
        id: '1',
        senderId: 'them',
        text: 'a',
        createdAt: DateTime(2026, 7, 26, 10, 0),
      );
      final b = ChatDetailGoldenFixtures.textMessage(
        id: '2',
        senderId: 'me',
        text: 'b',
        createdAt: DateTime(2026, 7, 27, 10, 0),
      );
      expect(shouldShowChatDateSeparator([a, b], 0), isTrue);
      expect(shouldShowChatDateSeparator([a, b], 1), isTrue);
      expect(formatChatMessageTime(a), '10:00');
    });
  });

  group('chat detail presentation widgets', () {
    testWidgets('wallpaper renders with overlay', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: QMatchChatBackground(child: SizedBox.expand()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('qmatch-chat-background')), findsOneWidget);
      expect(
        find.byKey(const Key('qmatch-chat-wallpaper-image')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('qmatch-chat-wallpaper-overlay')),
        findsOneWidget,
      );
    });

    test('debug traces do not change wallpaper path or add blur', () {
      final bg = File(
        'lib/features/messages/widgets/qmatch_chat_background.dart',
      ).readAsStringSync();
      expect(bg.contains('QMatchChatWallpaperAssets.runtimePrimary'), isTrue);
      expect(bg.contains('overlayOpacity = 0.55'), isTrue);
      expect(bg.contains('ImageFilter'), isFalse);
      expect(bg.contains('BackdropFilter'), isFalse);
      expect(bg.contains("QmatchPerf.mark('chat.wallpaper.loaded')"), isTrue);

      final screen = File(
        'lib/features/messages/screens/chat_detail_screen.dart',
      ).readAsStringSync();
      expect(screen.contains("QmatchPerf.mark('chat.detail.opened')"), isTrue);
      expect(
        screen.contains("QmatchPerf.mark('chat.messages.snapshot_ready')"),
        isTrue,
      );
      expect(screen.contains('threadId}'), isFalse);
    });

    testWidgets('incoming and outgoing bubbles align by sender',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: Column(
              children: [
                QMatchMessageBubble(
                  text: 'Incoming hello',
                  isOutgoing: false,
                  timestampText: '10:00',
                ),
                QMatchMessageBubble(
                  text: 'Outgoing hello',
                  isOutgoing: true,
                  timestampText: '10:01',
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-chat-bubble-in')), findsOneWidget);
      expect(find.byKey(const Key('qmatch-chat-bubble-out')), findsOneWidget);
      expect(find.text('Incoming hello'), findsOneWidget);
      expect(find.text('Outgoing hello'), findsOneWidget);
    });

    testWidgets('long / multiline / emoji messages render without overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: ListView(
              children: [
                QMatchMessageBubble(
                  text: ChatDetailGoldenFixtures.longMessage(me: 'me').text,
                  isOutgoing: true,
                ),
                QMatchMessageBubble(
                  text: ChatDetailGoldenFixtures.emojiMultiline(them: 'them')
                      .text,
                  isOutgoing: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('👋'), findsOneWidget);
    });

    testWidgets('empty / loading / error states render', (tester) async {
      await tester.pumpWidget(
        _wrapLocalized(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: QMatchChatEmptyState(
                        title: l10n.chatStartConversation,
                        body: l10n.chatEmptySubtitle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-chat-empty')), findsOneWidget);

      await tester.pumpWidget(
        _wrapLocalized(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: QMatchChatLoadingState(message: l10n.chatLoadingMessages),
              );
            },
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-chat-loading')), findsOneWidget);

      var retries = 0;
      await tester.pumpWidget(
        _wrapLocalized(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: QMatchChatErrorState(
                  title: l10n.chatMessagesLoadErrorTitle,
                  body: l10n.chatMessagesLoadErrorSubtitle,
                  retryLabel: l10n.retry,
                  onRetry: () => retries++,
                ),
              );
            },
          ),
        ),
      );
      expect(find.byKey(const Key('qmatch-chat-error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('qmatch-chat-error-retry')));
      expect(retries, 1);
    });

    testWidgets('missing avatar and missing display name are safe',
        (tester) async {
      await tester.pumpWidget(
        _wrapLocalized(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                appBar: QMatchConversationAppBar(
                  title: l10n.messagesConversationFallback,
                  loading: false,
                  photoUrl: null,
                  avatarSemanticLabel: l10n.messagesAvatarSemanticLabel(
                    l10n.messagesConversationFallback,
                  ),
                ),
                body: const SizedBox.shrink(),
              );
            },
          ),
        ),
      );
      expect(find.text('Conversation'), findsOneWidget);
      expect(
        find.byKey(const Key('qmatch-conversation-avatar-missing')),
        findsOneWidget,
      );
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('uid'), findsNothing);
    });

    testWidgets(
        'composer retains input during rebuild; send callback preserved',
        (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      var sends = 0;
      var rebuildToken = 0;

      Widget build() => _wrapLocalized(
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Scaffold(
                  body: Column(
                    children: [
                      Text('token-$rebuildToken'),
                      QMatchMessageComposer(
                        controller: controller,
                        focusNode: focus,
                        hintText: l10n.chatMessageHint,
                        sendSemanticLabel: l10n.chatSendSemanticLabel,
                        onSend: () => sends++,
                      ),
                    ],
                  ),
                );
              },
            ),
          );

      await tester.pumpWidget(build());
      await tester.enterText(
        find.byKey(const Key('qmatch-chat-composer-field')),
        'Keep me',
      );
      expect(controller.text, 'Keep me');
      rebuildToken = 1;
      await tester.pumpWidget(build());
      expect(controller.text, 'Keep me');
      await tester.tap(find.byKey(const Key('qmatch-chat-composer-send')));
      expect(sends, 1);
      await tester.tap(find.byKey(const Key('qmatch-chat-composer-send')));
      expect(sends, 2);
    });

    testWidgets('composer disables send while sending (no duplicate UX)',
        (tester) async {
      final controller = TextEditingController(text: 'Hi');
      final focus = FocusNode();
      var sends = 0;
      await tester.pumpWidget(
        _wrapLocalized(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: QMatchMessageComposer(
                  controller: controller,
                  focusNode: focus,
                  hintText: l10n.chatMessageHint,
                  sending: true,
                  onSend: () => sends++,
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('qmatch-chat-composer-send')));
      expect(sends, 0);
    });

    testWidgets('keyboard-sized viewInsets does not overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrapChatDetailGolden(
          surfaceSize: const Size(390, 844),
          viewInsets: const EdgeInsets.only(bottom: 300),
          child: const ChatDetailGoldenScene(
            variant: ChatDetailGoldenVariant.composerFocus,
            composerText: 'Typing…',
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('qmatch-chat-composer')), findsOneWidget);
    });

    testWidgets('wallpaper stays full width above keyboard; composer lifts',
        (tester) async {
      const size = Size(390, 844);
      const keyboard = 300.0;
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        wrapChatDetailGolden(
          surfaceSize: size,
          viewInsets: const EdgeInsets.only(bottom: keyboard),
          child: const ChatDetailGoldenScene(
            variant: ChatDetailGoldenVariant.composerFocus,
            composerText: 'Typing…',
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      final wallpaper = tester.getRect(
        find.byKey(const Key('qmatch-chat-wallpaper-image')),
      );
      expect(wallpaper.left, 0);
      expect(wallpaper.width, size.width);
      expect(wallpaper.right, size.width);

      final composer = tester.getRect(
        find.byKey(const Key('qmatch-chat-composer')),
      );
      expect(composer.bottom, lessThanOrEqualTo(size.height - keyboard + 0.5));
      expect(composer.width, size.width);
    });

    testWidgets('overflow menu is not gold and keeps three actions',
        (tester) async {
      var selected = <String>[];
      await tester.pumpWidget(
        _wrapLocalized(
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                appBar: QMatchConversationAppBar(
                  title: 'Ada',
                  loading: false,
                  menuItems: [
                    PopupMenuItem(
                      value: 'report',
                      child: Text(l10n.chatMenuReport),
                    ),
                    PopupMenuItem(
                      value: 'unmatch',
                      child: Text(l10n.chatMenuUnmatch),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Text(l10n.chatMenuBlock),
                    ),
                  ],
                  onMenuSelected: selected.add,
                ),
                body: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      await tester.pump();

      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('qmatch-chat-menu')),
          matching: find.byIcon(Icons.more_vert_rounded),
        ),
      );
      expect(icon.color, isNot(AppColors.softGold));
      expect(icon.color, isNot(AppColors.warmGold));
      expect(icon.color, isNot(AppColors.primary));

      final button = tester.widget<PopupMenuButton<String>>(
        find.byKey(const Key('qmatch-chat-menu')),
      );
      expect(button.color, isNot(AppColors.softGold));
      expect(button.color, AppColors.glassSurfaceStrong);

      await tester.tap(find.byKey(const Key('qmatch-chat-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('Unmatch'), findsOneWidget);
      expect(find.text('Block'), findsOneWidget);

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(selected, ['report']);
    });

    test('chat overflow icon source is not gold; handlers unchanged', () {
      final appBar = File(
        'lib/features/messages/widgets/qmatch_conversation_app_bar.dart',
      ).readAsStringSync();
      expect(appBar.contains('AppColors.softGold'), isFalse);
      expect(appBar.contains('AppColors.warmGold'), isFalse);
      expect(appBar.contains('Color(0xFFDAC8ED)'), isTrue);

      final screen = File(
        'lib/features/messages/screens/chat_detail_screen.dart',
      ).readAsStringSync();
      expect(screen.contains("case 'report':"), isTrue);
      expect(screen.contains("case 'unmatch':"), isTrue);
      expect(screen.contains("case 'block':"), isTrue);
      expect(screen.contains("case 'unblock':"), isTrue);
      expect(screen.contains('resizeToAvoidBottomInset: false'), isTrue);
      expect(screen.contains('viewInsetsOf(context).bottom'), isTrue);
    });

    testWidgets('no fabricated online/typing/read/compat chrome',
        (tester) async {
      await tester.pumpWidget(
        wrapChatDetailGolden(
          surfaceSize: ChatDetailGoldenFixtures.compactIphone,
          child: const ChatDetailGoldenScene(
            variant: ChatDetailGoldenVariant.mixed,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('online'), findsNothing);
      expect(find.textContaining('typing'), findsNothing);
      expect(find.textContaining('last seen'), findsNothing);
      expect(find.byIcon(Icons.done_all), findsNothing);
      expect(find.byIcon(Icons.done), findsNothing);
      expect(find.textContaining('compat'), findsNothing);
      expect(find.textContaining('persona'), findsNothing);
      expect(find.textContaining('Frequency'), findsNothing);
    });

    test('presentation widgets contain no Firebase writes', () {
      final widgetDir = Directory('lib/features/messages/widgets');
      for (final f in widgetDir.listSync().whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final src = f.readAsStringSync();
        expect(src.contains('FirebaseFirestore'), isFalse, reason: f.path);
        expect(src.contains('cloud_firestore'), isFalse, reason: f.path);
        expect(src.contains('sendTextMessage'), isFalse, reason: f.path);
        expect(src.contains('putFile'), isFalse, reason: f.path);
      }
    });

    testWidgets('strings use localization in scene', (tester) async {
      await tester.pumpWidget(
        wrapChatDetailGolden(
          surfaceSize: ChatDetailGoldenFixtures.compactIphone,
          child: const ChatDetailGoldenScene(
            variant: ChatDetailGoldenVariant.empty,
          ),
        ),
      );
      expect(find.text('Start the conversation.'), findsOneWidget);
      expect(
        find.text('Say hello when you are ready. There is no rush.'),
        findsOneWidget,
      );
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: child,
  );
}

Widget _wrapLocalized(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}
