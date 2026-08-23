import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/debug/qmatch_perf.dart';
import '../../../core/identity/identity.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../matching/services/match_service.dart';
import '../../safety/services/safety_service.dart';
import '../models/giphy_gif_model.dart';
import '../models/message_model.dart';
import '../services/chat_media_service.dart';
import '../services/chat_service.dart';
import '../services/giphy_service.dart';
import '../utils/chat_block_overflow.dart';
import '../utils/chat_message_timestamp_format.dart';
import '../utils/closed_account_chat_history.dart';
import '../widgets/chat_detail_widgets.dart';
import '../widgets/qmatch_image_message_bubble.dart';

enum _ChatAttachmentAction {
  photo,
  gif,
}

class ChatDetailScreen extends StatefulWidget {
  final String threadId;
  final String otherUserId;
  final String? otherUserName;

  const ChatDetailScreen({
    super.key,
    required this.threadId,
    required this.otherUserId,
    this.otherUserName,
    this.seedBlockedByMe,
    this.unblockUser,
    this.blockUser,
  });

  /// Tests seed owner-block state and skip live Firestore bootstrap.
  @visibleForTesting
  final bool? seedBlockedByMe;

  @visibleForTesting
  final Future<void> Function({required String blockedUid})? unblockUser;

  @visibleForTesting
  final Future<void> Function({
    required String blockedUid,
    String? matchId,
    String? threadId,
  })? blockUser;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  ChatService? _chat;
  SafetyService? _safety;
  MatchService? _matchService;
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  Map<String, dynamic>? _profile;
  bool _profileLoading = true;
  bool _sending = false;
  bool _bootstrapFailed = false;
  String? _matchId;
  bool _accountDeletionClosed = false;
  bool _blockedByMe = false;

  late Stream<List<MessageModel>> _messages;

  /// Avoid jumping on every StreamBuilder rebuild while the user scrolls.
  int _lastAutoScrollCount = -1;
  bool _loggedMessagesSnapshot = false;

  @override
  void initState() {
    super.initState();
    if (widget.seedBlockedByMe != null) {
      _messages = const Stream<List<MessageModel>>.empty();
    } else {
      _chat = ChatService();
      _safety = SafetyService();
      _matchService = MatchService();
      _messages = _chat!.getMessagesStream(widget.threadId);
    }
    QmatchPerf.mark('chat.detail.opened');
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant ChatDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.threadId != widget.threadId &&
        widget.seedBlockedByMe == null) {
      _messages = _chat!.getMessagesStream(widget.threadId);
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _profileLoading = true;
      _bootstrapFailed = false;
    });
    final seeded = widget.seedBlockedByMe;
    if (seeded != null) {
      if (!mounted) return;
      setState(() {
        _blockedByMe = seeded;
        _profileLoading = false;
        _matchId = widget.threadId;
        _accountDeletionClosed = false;
        _bootstrapFailed = false;
      });
      return;
    }
    try {
      final thread = await _chat!.markThreadAsRead(widget.threadId);
      final matchId = thread.matchId;
      final deletionClosed =
          ClosedAccountChatHistory.isAccountDeletionClosed(thread);

      Map<String, dynamic>? p;
      if (!deletionClosed) {
        p = await _chat!.getUserPublicProfile(widget.otherUserId);
      }

      var blockedByMe = false;
      try {
        blockedByMe = await _safety!.hasBlockedUser(widget.otherUserId);
      } catch (e, st) {
        debugPrint('ChatDetail block-state load failed: $e\n$st');
      }

      if (!mounted) return;
      setState(() {
        _profile = p;
        _profileLoading = false;
        _matchId = matchId;
        _accountDeletionClosed = deletionClosed;
        _blockedByMe = blockedByMe;
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
      await _chat!.sendTextMessage(widget.threadId, text);
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

  Future<void> _openAttachmentMenu() async {
    if (_accountDeletionClosed || _sending) return;

    _inputFocus.unfocus();

    final l10n = AppLocalizations.of(context)!;

    final selected = await showModalBottomSheet<_ChatAttachmentAction>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) {
        Widget action({
          required IconData icon,
          required String label,
          required _ChatAttachmentAction value,
        }) {
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(sheetContext).pop(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color:
                            AppColors.resonanceViolet.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.resonanceViolet.withValues(
                            alpha: 0.42,
                          ),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFFDAC8ED),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.glassSurfaceStrong,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Row(
                children: [
                  action(
                    icon: Icons.photo_library_outlined,
                    label: l10n.chatAttachmentPhoto,
                    value: _ChatAttachmentAction.photo,
                  ),
                  const SizedBox(width: 12),
                  action(
                    icon: Icons.gif_box_outlined,
                    label: l10n.chatAttachmentGif,
                    value: _ChatAttachmentAction.gif,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    if (selected == _ChatAttachmentAction.photo) {
      await _pickAndSendImage();
    } else {
      await _openGifPicker();
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_accountDeletionClosed || _sending) return;

    final l10n = AppLocalizations.of(context)!;
    final media = ChatMediaService();

    setState(() => _sending = true);

    try {
      final uploaded = await media.pickAndUploadImage(
        threadId: widget.threadId,
      );

      if (!mounted || uploaded == null || _accountDeletionClosed) {
        return;
      }

      await _chat!.sendImageMessage(
        threadId: widget.threadId,
        imageUrl: uploaded.downloadUrl,
        storagePath: uploaded.storagePath,
      );

      if (!mounted) return;

      _lastAutoScrollCount = -1;
      _scrollToBottom(force: true);
    } catch (e, st) {
      debugPrint('ChatDetail image send failed: $e\n$st');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatSendFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _openGifPicker() async {
    if (_accountDeletionClosed || _sending) return;

    final l10n = AppLocalizations.of(context)!;
    final giphy = GiphyService();

    if (!giphy.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatGifNotConfigured),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _inputFocus.unfocus();

    final selected = await showModalBottomSheet<GiphyGifModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: QMatchGifPicker(
              service: giphy,
              languageCode: Localizations.localeOf(context).languageCode,
              title: l10n.chatGifPickerTitle,
              searchHint: l10n.chatGifSearchHint,
              emptyText: l10n.chatGifEmpty,
              errorText: l10n.chatGifLoadError,
              poweredByText: l10n.chatGifPoweredBy,
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null || _accountDeletionClosed || _sending) {
      return;
    }

    setState(() => _sending = true);

    try {
      await _chat!.sendGifMessage(
        widget.threadId,
        selected.sendUrl,
      );

      unawaited(
        giphy.registerAnalytics(
          selected.analyticsSendUrl,
        ),
      );

      if (!mounted) return;

      _lastAutoScrollCount = -1;
      _scrollToBottom(force: true);
    } catch (e, st) {
      debugPrint('ChatDetail GIF send failed: $e\n$st');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.chatSendFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
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
      await _safety!.reportUser(
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
      await _matchService!.unmatch(matchId);
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
      final block = widget.blockUser;
      if (block != null) {
        await block(
          blockedUid: widget.otherUserId,
          matchId: matchId,
          threadId: widget.threadId,
        );
      } else {
        await _safety!.blockUser(
          blockedUid: widget.otherUserId,
          matchId: matchId,
          threadId: widget.threadId,
        );
      }
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

  Future<void> _confirmUnblock() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.chatUnblockDialogTitle,
          style: GoogleFonts.playfairDisplay(color: AppColors.primary),
        ),
        content: Text(
          l10n.chatUnblockDialogBody,
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
              l10n.unblock,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final unblock = widget.unblockUser;
      if (unblock != null) {
        await unblock(blockedUid: widget.otherUserId);
      } else {
        await _safety!.unblockUser(blockedUid: widget.otherUserId);
      }
      if (!mounted) return;
      setState(() => _blockedByMe = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatUserUnblocked),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e, st) {
      debugPrint('ChatDetail unblock failed: $e\n$st');
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

  Future<void> _toggleReaction({
    required MessageModel message,
    required String reaction,
  }) async {
    if (_accountDeletionClosed) return;

    try {
      await _chat!.toggleMessageReaction(
        threadId: widget.threadId,
        messageId: message.messageId,
        reaction: reaction,
      );
    } catch (e, st) {
      debugPrint('ChatDetail reaction failed: $e\n$st');

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatActionFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showReactionPicker(
    MessageModel message,
    Offset globalPosition,
  ) async {
    if (_accountDeletionClosed) return;
    if (message.type != MessageType.text &&
        message.type != MessageType.gif &&
        message.type != MessageType.image) {
      return;
    }
    if (message.senderId == 'system') return;

    final media = MediaQuery.of(context);
    const panelWidth = 318.0;
    const panelHeight = 66.0;
    const horizontalMargin = 12.0;

    final maxLeft = (media.size.width - panelWidth - horizontalMargin)
        .clamp(horizontalMargin, double.infinity)
        .toDouble();

    final left = (globalPosition.dx - (panelWidth / 2))
        .clamp(horizontalMargin, maxLeft)
        .toDouble();

    var top = globalPosition.dy - panelHeight - 18;

    final minTop = media.padding.top + 8;
    if (top < minTop) {
      top = globalPosition.dy + 18;
    }

    if (top + panelHeight > media.size.height - media.padding.bottom - 8) {
      top = media.size.height - media.padding.bottom - panelHeight - 8;
    }

    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.16),
      builder: (dialogContext) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: panelWidth,
                height: panelHeight,
                child: Material(
                  color: AppColors.glassSurfaceStrong,
                  elevation: 14,
                  shadowColor: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 6,
                    ),
                    child: Row(
                      children: ChatService.supportedMessageReactions
                          .map(
                            (reaction) => Expanded(
                              child: InkWell(
                                key: Key(
                                  'qmatch-message-reaction-picker-$reaction',
                                ),
                                onTap: () => Navigator.of(
                                  dialogContext,
                                ).pop(reaction),
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: Text(
                                    reaction,
                                    style: const TextStyle(
                                      fontSize: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    await _toggleReaction(
      message: message,
      reaction: selected,
    );
  }

  Widget _buildReactionBadge({
    required MessageModel message,
    required String currentUid,
  }) {
    final counts = <String, int>{};

    for (final reaction in message.reactions.values) {
      if (!ChatService.supportedMessageReactions.contains(reaction)) {
        continue;
      }
      counts[reaction] = (counts[reaction] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    final ordered = ChatService.supportedMessageReactions
        .where(counts.containsKey)
        .toList();

    final totalCount = counts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    final myReaction = message.reactions[currentUid];
    final selectedByMe = myReaction != null &&
        ChatService.supportedMessageReactions.contains(myReaction);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key(
          'qmatch-message-reaction-${message.messageId}',
        ),
        onTap: _accountDeletionClosed || !selectedByMe
            ? null
            : () => _toggleReaction(
                  message: message,
                  reaction: myReaction,
                ),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(
            minHeight: 26,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: selectedByMe
                ? AppColors.resonanceViolet.withValues(alpha: 0.34)
                : AppColors.glassSurfaceStrong,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selectedByMe
                  ? AppColors.resonanceViolet.withValues(alpha: 0.72)
                  : AppColors.borderSubtle,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < ordered.length; i++) ...[
                if (i > 0) const SizedBox(width: 2),
                Text(
                  ordered[i],
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1,
                  ),
                ),
              ],
              if (totalCount > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '$totalCount',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent({
    required MessageModel message,
    required bool isOutgoing,
    required String? timestampText,
  }) {
    switch (message.type) {
      case MessageType.gif:
        return QMatchGifMessageBubble(
          gifUrl: message.gifUrl ?? '',
          isOutgoing: isOutgoing,
          timestampText: timestampText,
        );
      case MessageType.image:
        return QMatchImageMessageBubble(
          imageUrl: message.imageUrl ?? '',
          isOutgoing: isOutgoing,
          timestampText: timestampText,
        );
      case MessageType.text:
      case MessageType.revealRequest:
      case MessageType.system:
        return QMatchMessageBubble(
          text: message.text,
          isOutgoing: isOutgoing,
          timestampText: timestampText,
        );
    }
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
        final timestampText = formatChatMessageTime(m);
        final hasReaction = m.reactions.values.any(
          ChatService.supportedMessageReactions.contains,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSep && day != null)
              QMatchDateSeparator(label: _dateSeparatorLabel(l10n, day)),
            if (isSystem)
              QMatchMessageBubble(
                text: m.text,
                isOutgoing: false,
                isSystem: true,
                timestampText: formatChatMessageTime(m),
              )
            else if (!hasReaction)
              GestureDetector(
                key: Key(
                  'qmatch-message-reaction-target-${m.messageId}',
                ),
                behavior: HitTestBehavior.translucent,
                onLongPressStart: _accountDeletionClosed
                    ? null
                    : (details) => _showReactionPicker(
                          m,
                          details.globalPosition,
                        ),
                child: _buildMessageContent(
                  message: m,
                  isOutgoing: isOutgoing,
                  timestampText: timestampText,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          key: Key(
                            'qmatch-message-reaction-target-${m.messageId}',
                          ),
                          behavior: HitTestBehavior.translucent,
                          onLongPressStart: _accountDeletionClosed
                              ? null
                              : (details) => _showReactionPicker(
                                    m,
                                    details.globalPosition,
                                  ),
                          child: _buildMessageContent(
                            message: m,
                            isOutgoing: isOutgoing,
                            timestampText: null,
                          ),
                        ),
                        Positioned(
                          right: isOutgoing ? 2 : null,
                          left: isOutgoing ? null : 2,
                          bottom: -7,
                          child: _buildReactionBadge(
                            message: m,
                            currentUid: currentUid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (timestampText != null && timestampText.trim().isNotEmpty)
                    QMatchMessageTimestamp(
                      text: timestampText,
                      alignEnd: isOutgoing,
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUid = widget.seedBlockedByMe != null
        ? 'seed-uid'
        : FirebaseAuth.instance.currentUser?.uid;
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
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                l10n.chatMenuReport,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
              ),
            ),
          ),
          if (!_accountDeletionClosed)
            PopupMenuItem(
              value: 'unmatch',
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  l10n.chatMenuUnmatch,
                  style: GoogleFonts.inter(color: AppColors.danger),
                ),
              ),
            ),
          PopupMenuItem(
            value: chatBlockOverflowValue(blockedByMe: _blockedByMe),
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                chatBlockOverflowLabel(
                  l10n,
                  blockedByMe: _blockedByMe,
                ),
                style: GoogleFonts.inter(
                  color:
                      _blockedByMe ? AppColors.textPrimary : AppColors.danger,
                ),
              ),
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
            case 'unblock':
              await _confirmUnblock();
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
                      attachmentSemanticLabel: l10n.chatAttachmentSemanticLabel,
                      onAttachment: _openAttachmentMenu,
                      onSend: _send,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
