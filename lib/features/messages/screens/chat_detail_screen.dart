import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../../safety/services/safety_service.dart';
import '../../matching/services/match_service.dart';

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
  String? _initError;
  String? _matchId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _chat.markThreadAsRead(widget.threadId);
      final thread = await _chat.getThreadById(widget.threadId);
      final matchId = thread?.matchId;
      final p = await _chat.getUserPublicProfile(widget.otherUserId);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _profileLoading = false;
        _matchId = matchId;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _input.text;
    if (_sending) return;
    if (text.trim().isEmpty) return;

    setState(() => _sending = true);
    try {
      await _chat.sendTextMessage(widget.threadId, text);
      if (!mounted) return;
      _input.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _resolveTitle(AppLocalizations l10n) {
    final fromProp = widget.otherUserName?.trim();
    if (fromProp != null && fromProp.isNotEmpty) return fromProp;
    final fromProfile = (_profile?['name'] as String?)?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    return l10n.messagesConversationFallback;
  }

  String? _resolvePhotoUrl() {
    final direct = (_profile?['profile_photo_url'] as String?)?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final photos = (_profile?['photos'] as List?)?.cast<String>() ?? const <String>[];
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
                        .map((r) => DropdownMenuItem(
                              value: r.$1,
                              child: Text(r.$2, style: GoogleFonts.inter(color: Colors.white)),
                            ))
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
                      hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
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
              child: Text(l10n.cancel, style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.submit, style: GoogleFonts.inter(color: AppColors.primary)),
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
        details: detailsCtrl.text.trim().isEmpty ? null : detailsCtrl.text.trim(),
        matchId: matchId,
        threadId: widget.threadId,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.chatReportSubmitted), backgroundColor: AppColors.success),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
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
        SnackBar(content: Text(l10n.chatMatchNotFound), backgroundColor: AppColors.error),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.chatUnmatchDialogTitle, style: GoogleFonts.playfairDisplay(color: AppColors.primary)),
        content: Text(
          l10n.chatUnmatchDialogBody,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.chatMenuUnmatch, style: GoogleFonts.inter(color: Colors.red)),
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
        SnackBar(content: Text(l10n.chatMatchRemoved), backgroundColor: AppColors.success),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
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
        title: Text(l10n.chatBlockDialogTitle, style: GoogleFonts.playfairDisplay(color: AppColors.primary)),
        content: Text(
          l10n.chatBlockDialogBody,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.chatMenuBlock, style: GoogleFonts.inter(color: Colors.red)),
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
        SnackBar(content: Text(l10n.chatUserBlocked), backgroundColor: AppColors.success),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        titleSpacing: 8,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primary),
            color: AppColors.surface,
            onSelected: (value) async {
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
            itemBuilder: (context) => [
              PopupMenuItem(value: 'report', child: Text(l10n.chatMenuReport)),
              PopupMenuItem(value: 'unmatch', child: Text(l10n.chatMenuUnmatch)),
              PopupMenuItem(value: 'block', child: Text(l10n.chatMenuBlock)),
            ],
          ),
        ],
        title: _profileLoading
            ? Text(
                l10n.loading,
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Row(
                children: [
                  _HeaderAvatar(photoUrl: _resolvePhotoUrl()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _resolveTitle(l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          if (_initError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _initError!,
                style: GoogleFonts.inter(color: AppColors.error, fontSize: 12),
              ),
            ),
          Expanded(
            child: currentUid == null
                ? Center(
                    child: Text(
                      l10n.loginRequired,
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  )
                : StreamBuilder<List<MessageModel>>(
                    stream: _chat.getMessagesStream(widget.threadId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              l10n.messagesLoadErrorTitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        );
                      }

                      final messages = snapshot.data ?? const [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.chatStartConversation,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.playfairDisplay(
                                    color: AppColors.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  l10n.messagesEmptySubtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      _scrollToBottom();

                      return Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scroll,
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final m = messages[index];
                                return _MessageBubble(
                                  message: m,
                                  currentUid: currentUid,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _inputFocus,
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      enabled: !_sending,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: l10n.chatMessageHint,
                        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  final String? photoUrl;
  const _HeaderAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Icon(
        Icons.person,
        color: AppColors.primary.withValues(alpha: 0.6),
        size: 18,
      ),
    );

    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) return placeholder;

    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String currentUid;

  const _MessageBubble({
    required this.message,
    required this.currentUid,
  });

  bool get _isSystem =>
      message.type == MessageType.system || message.senderId == 'system';

  @override
  Widget build(BuildContext context) {
    if (_isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary.withValues(alpha: 0.95),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    final isMe = message.senderId == currentUid;
    final time = _formatTime(message);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    message.text,
                    style: GoogleFonts.inter(
                      color: isMe ? Colors.black : Colors.white,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              if (time != null) ...[
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary.withValues(alpha: 0.75),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _formatTime(MessageModel m) {
    final ts = m.createdAt;
    if (ts != null) {
      final d = ts.toDate();
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    final ms = m.clientCreatedAt;
    if (ms == null) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
