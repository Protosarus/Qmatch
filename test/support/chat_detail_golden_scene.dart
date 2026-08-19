import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qmatch/core/theme/app_colors.dart';
import 'package:qmatch/features/messages/models/message_model.dart';
import 'package:qmatch/features/messages/utils/chat_message_timestamp_format.dart';
import 'package:qmatch/features/messages/widgets/chat_detail_widgets.dart';
import 'package:qmatch/l10n/app_localizations.dart';

import 'chat_detail_golden_fixtures.dart';

enum ChatDetailGoldenVariant {
  empty,
  loading,
  error,
  incoming,
  outgoing,
  mixed,
  longMessage,
  emojiMultiline,
  missingCounterpart,
  composerFocus,
}

/// Test-only chat-detail scene (no Firebase / production routes).
class ChatDetailGoldenScene extends StatelessWidget {
  const ChatDetailGoldenScene({
    super.key,
    required this.variant,
    this.currentUid = 'me_uid',
    this.counterpartName = 'Ada',
    this.counterpartPhotoProvider,
    this.messages,
    this.sending = false,
    this.composerText = '',
  });

  final ChatDetailGoldenVariant variant;
  final String currentUid;
  final String counterpartName;
  final ImageProvider? counterpartPhotoProvider;
  final List<MessageModel>? messages;
  final bool sending;
  final String composerText;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final title = counterpartName.trim().isEmpty
            ? l10n.messagesConversationFallback
            : counterpartName;
        final controller = TextEditingController(text: composerText);
        final focus = FocusNode();

        Widget bodyChild;
        switch (variant) {
          case ChatDetailGoldenVariant.loading:
            bodyChild = QMatchChatLoadingState(
              message: l10n.chatLoadingMessages,
            );
          case ChatDetailGoldenVariant.empty:
            bodyChild = QMatchChatEmptyState(
              title: l10n.chatStartConversation,
              body: l10n.chatEmptySubtitle,
            );
          case ChatDetailGoldenVariant.error:
            bodyChild = QMatchChatErrorState(
              title: l10n.chatMessagesLoadErrorTitle,
              body: l10n.chatMessagesLoadErrorSubtitle,
              retryLabel: l10n.retry,
              onRetry: () {},
            );
          case ChatDetailGoldenVariant.incoming:
          case ChatDetailGoldenVariant.outgoing:
          case ChatDetailGoldenVariant.mixed:
          case ChatDetailGoldenVariant.longMessage:
          case ChatDetailGoldenVariant.emojiMultiline:
          case ChatDetailGoldenVariant.missingCounterpart:
          case ChatDetailGoldenVariant.composerFocus:
            final list = messages ?? _defaultMessages(variant);
            bodyChild = ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final m = list[index];
                final showSep = shouldShowChatDateSeparator(list, index);
                final day = messageLocalDay(m);
                final isSystem =
                    m.type == MessageType.system || m.senderId == 'system';
                final isOutgoing = !isSystem && m.senderId == currentUid;
                final now = DateTime(2026, 7, 27, 18, 0);
                String? sepLabel;
                if (showSep && day != null) {
                  sepLabel = isSameLocalDay(day, DateTime(2026, 7, 27))
                      ? l10n.chatDateToday
                      : formatChatDateCompact(day, now: now);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (sepLabel != null) QMatchDateSeparator(label: sepLabel),
                    QMatchMessageBubble(
                      text: m.text,
                      isOutgoing: isOutgoing,
                      isSystem: isSystem,
                      timestampText: formatChatMessageTime(m),
                    ),
                  ],
                );
              },
            );
        }

        return Scaffold(
          backgroundColor: AppColors.cosmicBlack,
          resizeToAvoidBottomInset: false,
          appBar: QMatchConversationAppBar(
            title: title,
            loading: false,
            photoUrl: null,
            photoImageProvider: counterpartPhotoProvider,
            avatarSemanticLabel: l10n.messagesAvatarSemanticLabel(title),
            menuItems: [
              PopupMenuItem(
                value: 'report',
                child: Text(
                  l10n.chatMenuReport,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                ),
              ),
            ],
            onMenuSelected: (_) {},
          ),
          body: QMatchChatBackground(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: [
                  Expanded(child: bodyChild),
                  QMatchMessageComposer(
                    controller: controller,
                    focusNode: focus,
                    hintText: l10n.chatMessageHint,
                    sending: sending,
                    sendSemanticLabel: l10n.chatSendSemanticLabel,
                    onSend: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<MessageModel> _defaultMessages(ChatDetailGoldenVariant v) {
    switch (v) {
      case ChatDetailGoldenVariant.incoming:
        return [
          ChatDetailGoldenFixtures.textMessage(
            id: 'in',
            senderId: 'them',
            text: 'Hello from Ada.',
            createdAt: DateTime(2026, 7, 27, 14, 22),
          ),
        ];
      case ChatDetailGoldenVariant.outgoing:
        return [
          ChatDetailGoldenFixtures.textMessage(
            id: 'out',
            senderId: currentUid,
            text: 'Hello from me.',
            createdAt: DateTime(2026, 7, 27, 14, 23),
          ),
        ];
      case ChatDetailGoldenVariant.mixed:
        return ChatDetailGoldenFixtures.mixedConversation(
          me: currentUid,
          them: 'them',
        );
      case ChatDetailGoldenVariant.longMessage:
        return [ChatDetailGoldenFixtures.longMessage(me: currentUid)];
      case ChatDetailGoldenVariant.emojiMultiline:
        return [ChatDetailGoldenFixtures.emojiMultiline(them: 'them')];
      case ChatDetailGoldenVariant.missingCounterpart:
        return [
          ChatDetailGoldenFixtures.textMessage(
            id: 'x',
            senderId: 'them',
            text: 'Still here.',
            createdAt: DateTime(2026, 7, 27, 15, 0),
          ),
        ];
      case ChatDetailGoldenVariant.composerFocus:
        return [
          ChatDetailGoldenFixtures.textMessage(
            id: 'c',
            senderId: 'them',
            text: 'Ready when you are.',
            createdAt: DateTime(2026, 7, 27, 16, 0),
          ),
        ];
      default:
        return const [];
    }
  }
}

Widget wrapChatDetailGolden({
  required Widget child,
  required Size surfaceSize,
  double textScale = 1.0,
  EdgeInsets padding = const EdgeInsets.only(bottom: 34),
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
    ),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: MediaQuery(
      data: MediaQueryData(
        size: surfaceSize,
        padding: padding,
        viewPadding: padding,
        viewInsets: viewInsets,
        textScaler: TextScaler.linear(textScale),
        devicePixelRatio: 1.0,
      ),
      child: SizedBox(
        width: surfaceSize.width,
        height: surfaceSize.height,
        child: child,
      ),
    ),
  );
}
