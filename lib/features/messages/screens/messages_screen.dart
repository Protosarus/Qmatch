import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/identity/identity.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../models/chat_thread_model.dart';
import '../services/chat_service.dart';
import '../utils/closed_account_chat_history.dart';
import '../utils/conversation_timestamp_format.dart';
import '../widgets/messages_widgets.dart';
import 'chat_detail_screen.dart';

/// Messages inbox (conversation list). Presentation migrated in P2C-1C-3A.
///
/// Firestore stream / ChatService behavior is unchanged.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatService _chatService = ChatService();

  /// Bumping recreates the StreamBuilder subscription (real retry).
  int _streamEpoch = 0;

  void _retryStream() {
    setState(() => _streamEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: const Key('qmatch-messages-screen'),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QMatchMessagesHeader(title: l10n.messagesTitle),
            Expanded(
              child: StreamBuilder<List<ChatThreadModel>>(
                key: ValueKey('messages-stream-$_streamEpoch'),
                stream: _chatService.getMyThreadsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData &&
                      !snapshot.hasError) {
                    return QMatchMessagesLoadingState(
                      message: l10n.messagesLoading,
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint('Messages stream error: ${snapshot.error}');
                    return QMatchMessagesErrorState(
                      title: l10n.messagesLoadErrorTitle,
                      body: l10n.messagesLoadErrorSubtitle,
                      retryLabel: l10n.retry,
                      onRetry: _retryStream,
                    );
                  }

                  final threads = snapshot.data ?? const <ChatThreadModel>[];
                  if (threads.isEmpty) {
                    return QMatchMessagesEmptyState(
                      title: l10n.messagesEmptyTitle,
                      body: l10n.messagesEmptySubtitle,
                    );
                  }

                  return ListView.separated(
                    key: const Key('qmatch-messages-list'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    itemCount: threads.length,
                    separatorBuilder: (_, __) =>
                        const QMatchConversationListSeparator(),
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return _MessagesThreadRow(
                        thread: thread,
                        chatService: _chatService,
                        onOpen: (otherUserId, otherName) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                threadId: thread.threadId,
                                otherUserId: otherUserId,
                                otherUserName: otherName,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolves counterpart public profile via existing [ChatService], then renders
/// a presentation-only tile. Keeps Firestore out of widget components.
class _MessagesThreadRow extends StatelessWidget {
  const _MessagesThreadRow({
    required this.thread,
    required this.chatService,
    required this.onOpen,
  });

  final ChatThreadModel thread;
  final ChatService chatService;
  final void Function(String otherUserId, String? otherUserName) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const SizedBox.shrink();
    }

    late final String otherId;
    try {
      otherId = chatService.getOtherParticipantId(thread, currentUid);
    } catch (e) {
      debugPrint('Messages invalid participants for ${thread.threadId}: $e');
      return const SizedBox.shrink();
    }

    final unread = thread.unreadCounts[currentUid] ?? 0;
    final localeCode = Localizations.maybeLocaleOf(context)?.languageCode;
    final timeText = formatConversationTimestamp(
      thread.lastMessageAt,
      localeCode: localeCode,
    );
    final deletionClosed =
        ClosedAccountChatHistory.isAccountDeletionClosed(thread);

    if (deletionClosed) {
      final displayName = l10n.chatUnavailablePeerTitle;
      final preview = thread.lastMessagePreview?.trim().isNotEmpty == true
          ? thread.lastMessagePreview!.trim()
          : l10n.chatConversationNoLongerActive;
      return QMatchConversationTile(
        key: ValueKey('deletion-closed-${thread.threadId}'),
        displayName: displayName,
        age: null,
        photoUrl: null,
        previewText: preview,
        timestampText: timeText,
        unreadCount: unread,
        avatarSemanticLabel: l10n.messagesAvatarSemanticLabel(displayName),
        unreadSemanticLabel:
            unread > 0 ? l10n.messagesUnreadSemanticLabel(unread) : null,
        rowSemanticLabel: l10n.messagesConversationSemanticLabel(displayName),
        onTap: () => onOpen(otherId, null),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: chatService.getUserPublicProfile(otherId),
      builder: (context, snap) {
        final profile = snap.data;
        final resolved = UserIdentityResolver.fromUserMap(profile);
        final profilePhotoUrl =
            (profile?['profile_photo_url'] as String?)?.trim();
        final photos =
            (profile?['photos'] as List?)?.cast<String>() ?? const <String>[];

        final photoUrl = (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
            ? profilePhotoUrl
            : (photos.isNotEmpty ? photos.first : null);

        // Missing/deleted counterpart → localized fallback (never raw uid/email).
        final displayName = resolved.hasDisplayName
            ? resolved.displayName!
            : l10n.messagesConversationFallback;

        final preview = thread.lastMessagePreview?.trim().isNotEmpty == true
            ? thread.lastMessagePreview!.trim()
            : l10n.messagesSayHi;

        return QMatchConversationTile(
          displayName: displayName,
          age: resolved.hasDisplayName ? resolved.age : null,
          photoUrl: photoUrl,
          previewText: preview,
          timestampText: timeText,
          unreadCount: unread,
          avatarSemanticLabel: l10n.messagesAvatarSemanticLabel(displayName),
          unreadSemanticLabel:
              unread > 0 ? l10n.messagesUnreadSemanticLabel(unread) : null,
          rowSemanticLabel: l10n.messagesConversationSemanticLabel(displayName),
          onTap: () => onOpen(
            otherId,
            resolved.hasDisplayName ? resolved.displayName : null,
          ),
        );
      },
    );
  }
}
