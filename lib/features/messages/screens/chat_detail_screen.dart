import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/debug/qmatch_perf.dart';
import '../../../core/identity/identity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../matching/services/match_service.dart';
import '../../safety/services/safety_service.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../utils/chat_message_timestamp_format.dart';
import '../utils/closed_account_chat_history.dart';
import '../widgets/chat_detail_widgets.dart';

class ChatDetailScreen extends StatefulWidget {
  final String threadId;
  final String otherUserId;
  final String? otherUserName;

  const ChatDetailScreen({
    super.key,
    required this.threadId,
    required this.otherUserId,
    this.otherUserName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chat = ChatService();
  final SafetyService _safety = SafetyService();
  final MatchService _matchService = MatchService();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  Map<String, dynamic>? _profile;
  bool _profileLoading = true;
  bool _sending = false;
  bool _bootstrapFailed = false;
  String? _matchId;
  bool _accountDeletionClosed = false;

  late Stream<List<MessageModel>> _messages;

  /// Avoid jumping on every StreamBuilder rebuild while the user scrolls.
  int _lastAutoScrollCount = -1;
  bool _loggedMessagesSnapshot = false;

  @override
  void initState() {
    super.initState();
    _messages = _chat.getMessagesStream(widget.threadId);
    QmatchPerf.mark('chat.detail.opened');
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant ChatDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.threadId != widget.threadId) {
      _messages = _chat.getMessagesStream(widget.threadId);
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _profileLoading = true;
      _bootstrapFailed = false;
    });
    try {
      final thread = await _chat.markThreadAsRead(widget.threadId);
      final matchId = thread.matchId;
      final deletionClosed =
          ClosedAccountChatHistory.isAccountDeletionClosed(thread);

      Map<String, dynamic>? p;
      if (!deletionClosed) {
        p = await _chat.getUserPublicProfile(widget.otherUserId);
      }

      if (!mounted) return;
      setState(() {
        _profile = p;
        _profileLoading = false;
        _matchId = matchId;
        _accountDeletionClosed = deletionClosed;
        _bootstrapFailed = false;
      });
    } catch (e, st) {
      debugPrint('ChatDetail bootstrap failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _bootstrapFailed = true;
        _profileLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    if (_accountDeletionClosed) return;
    final text = _input.text;
    if (_sending) return;
    if (text.trim().isEmpty) return;

    setState(() => _sending = true);
    try {
      await _chat.sendTextMessage(widget.threadId, text);
      if (!mounted) return;
      _input.clear();
      _lastAutoScrollCount = -1;
      _scrollToBottom(force: true);
    } catch (e, st) {
      debugPrint('ChatDetail send failed: $e\n$st');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatSendFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _resolveTitle(AppLocalizations l10n) {
    if (_accountDeletionClosed) {
      return l10n.chatUnavailablePeerTitle;
    }
    final fromProp = widget.otherUserName;
    if (fromProp != null) {
      final coerced = UserIdentityResolver.coerceForDisplay(fromProp);
      if (coerced != null) return coerced;
    }
    final resolved = UserIdentityResolver.fromUserMap(_profile);
    if (resolved.hasDisplayName) return resolved.displayName!;
    return l10n.messagesConversationFallback;
  }

  String? _resolvePhotoUrl() {
    if (_accountDeletionClosed) return null;
    final direct = (_profile?['profile_photo_url'] as String?)?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final photos =
        (_profile?['photos'] as List?)?.cast<String>() ?? const <String>[];
    for (final u in photos) {
      if (u.trim().isNotEmpty) return u;
    }
    return null;
  }

  Future<void> _showReportDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final matchId = _matchId;
    final messenger = ScaffoldMessenger.of(context);

    final reasons = [
      ('harassment', l10n.chatReportReasonHarassment),
      ('spam', l10n.chatReportReasonSpam),
      ('impersonation', l10n.chatReportReasonImpersonation),
      ('inappropriate_content', l10n.chatReportReasonInappropriate),
      ('scam', l10n.chatReportReasonScam),
      ('other', l10n.chatReportReasonOther),
    ];

    String selected = reasons.first.$1;
    final detailsCtrl = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            l10n.chatReportDialogTitle,
            style: GoogleFonts.playfairDisplay(color: AppColors.primary),
          ),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chatReportDialogSubtitle,
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    dropdownColor: AppColors.surface,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(),
                    ),
                    items: reasons
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.$1,
                            child: Text(
                              r.$2,
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selected = v ?? selected),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailsCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l10n.chatReportDetailsHint,
                      hintStyle:
                          GoogleFonts.inter(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.submit,
                style: GoogleFonts.inter(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );

    if (submitted != true) {
      detailsCtrl.dispose();
      return;
    }

    try {
      await _safety.reportUser(
        reportedUid: widget.otherUserId,
        reason: selected,
        details:
            detailsCtrl.text.trim().isEmpty ? null : detailsCtrl.text.trim(),
        matchId: matchId,
        threadId: widget.threadId,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatReportSubmitted),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e, st) {
      debugPrint('ChatDetail report failed: $e\n$st');
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatActionFailed),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      detailsCtrl.dispose();
    }
  }

  Future<void> _confirmUnmatch() async {
    final l10n = AppLocalizations.of(context)!;
    final matchId = _matchId;
    if (matchId == null || matchId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatMatchNotFound),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.chatUnmatchDialogTitle,
          style: GoogleFonts.playfairDisplay(color: AppColors.primary),
        ),
        content: Text(
          l10n.chatUnmatchDialogBody,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.chatMenuUnmatch,
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _matchService.unmatch(matchId);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatMatchRemoved),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e, st) {
      debugPrint('ChatDetail unmatch failed: $e\n$st');
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatActionFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmBlock() async {
    final l10n = AppLocalizations.of(context)!;
    final matchId = _matchId;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.chatBlockDialogTitle,
          style: GoogleFonts.playfairDisplay(color: AppColors.primary),
        ),
        content: Text(
          l10n.chatBlockDialogBody,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.chatMenuBlock,
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _safety.blockUser(
        blockedUid: widget.otherUserId,
        matchId: matchId,
        threadId: widget.threadId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatUserBlocked),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e, st) {
      debugPrint('ChatDetail block failed: $e\n$st');
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatActionFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _dateSeparatorLabel(AppLocalizations l10n, DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (isSameLocalDay(day, today)) return l10n.chatDateToday;
    return formatChatDateCompact(day, now: now);
  }

  Widget _buildMessageList({
    required List<MessageModel> messages,
    required String currentUid,
    required AppLocalizations l10n,
  }) {
    if (messages.length != _lastAutoScrollCount) {
      _lastAutoScrollCount = messages.length;
      _scrollToBottom();
    }

    return ListView.builder(
      key: const Key('qmatch-chat-message-list'),
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final m = messages[index];
        final showSep = shouldShowChatDateSeparator(messages, index);
        final day = messageLocalDay(m);
        final isSystem = m.type == MessageType.system || m.senderId == 'system';
        final isOutgoing = !isSystem && m.senderId == currentUid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSep && day != null)
              QMatchDateSeparator(label: _dateSeparatorLabel(l10n, day)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final title = _resolveTitle(l10n);

    return Scaffold(
      backgroundColor: AppColors.cosmicBlack,
      resizeToAvoidBottomInset: false,
      appBar: QMatchConversationAppBar(
        title: _profileLoading ? l10n.loading : title,
        loading: _profileLoading,
        photoUrl: _resolvePhotoUrl(),
        avatarSemanticLabel: l10n.messagesAvatarSemanticLabel(title),
        // No profile deep-link from chat title (active or deletion-closed).
        onTitleTap: null,
        menuItems: [
          PopupMenuItem(
            value: 'report',
            child: Text(
              l10n.chatMenuReport,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
          ),
          if (!_accountDeletionClosed)
            PopupMenuItem(
              value: 'unmatch',
              child: Text(
                l10n.chatMenuUnmatch,
                style: GoogleFonts.inter(color: AppColors.danger),
              ),
            ),
          PopupMenuItem(
            value: 'block',
            child: Text(
              l10n.chatMenuBlock,
              style: GoogleFonts.inter(color: AppColors.danger),
            ),
          ),
        ],
        onMenuSelected: (value) async {
          switch (value) {
            case 'report':
              await _showReportDialog();
              break;
            case 'unmatch':
              await _confirmUnmatch();
              break;
            case 'block':
              await _confirmBlock();
              break;
          }
        },
      ),
      body: QMatchChatBackground(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
            if (_bootstrapFailed)
              Material(
                color: AppColors.danger.withValues(alpha: 0.16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          key: const Key('qmatch-chat-profile-error'),
                          l10n.chatProfileLoadErrorSubtitle,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('qmatch-chat-profile-error-retry'),
                        onPressed: _bootstrap,
                        child: Text(
                          l10n.retry,
                          style: GoogleFonts.inter(
                            color: AppColors.softGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: currentUid == null
                  ? Center(
                      child: Text(
                        l10n.loginRequired,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : StreamBuilder<List<MessageModel>>(
                      stream: _messages,
                      builder: (context, snapshot) {
                        if (!_loggedMessagesSnapshot &&
                            (snapshot.hasData || snapshot.hasError)) {
                          _loggedMessagesSnapshot = true;
                          QmatchPerf.mark('chat.messages.snapshot_ready');
                        }
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return QMatchChatLoadingState(
                            message: l10n.chatLoadingMessages,
                          );
                        }

                        if (snapshot.hasError) {
                          debugPrint(
                            'ChatDetail messages stream error: ${snapshot.error}',
                          );
                          return QMatchChatErrorState(
                            title: l10n.chatMessagesLoadErrorTitle,
                            body: l10n.chatMessagesLoadErrorSubtitle,
                          );
                        }

                        final messages = snapshot.data ?? const [];
                        if (messages.isEmpty) {
                          return QMatchChatEmptyState(
                            title: l10n.chatStartConversation,
                            body: l10n.chatEmptySubtitle,
                          );
                        }

                        return _buildMessageList(
                          messages: messages,
                          currentUid: currentUid,
                          l10n: l10n,
                        );
                      },
                    ),
            ),
            _accountDeletionClosed
                ? QMatchConversationInactiveBanner(
                    message: l10n.chatConversationNoLongerActive,
                  )
                : QMatchMessageComposer(
                    controller: _input,
                    focusNode: _inputFocus,
                    hintText: l10n.chatMessageHint,
                    sending: _sending,
                    enabled: true,
                    sendSemanticLabel: l10n.chatSendSemanticLabel,
                    onSend: _send,
                  ),
          ],
          ),
        ),
      ),
    );
  }
}
