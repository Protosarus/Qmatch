import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_thread_model.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Row(
                children: [
                  Text(
                    'Mesajlar',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatThreadModel>>(
                stream: chatService.getMyThreadsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 56,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Could not load conversations.',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please try again in a moment.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final threads = snapshot.data ?? const [];
                  if (threads.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 72,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No conversations yet',
                              style: GoogleFonts.playfairDisplay(
                                color: AppColors.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'When you match with someone, your conversation will appear here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: threads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return _ThreadTile(
                        thread: thread,
                        chatService: chatService,
                        onTap: (otherUserId, otherName) {
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

class _ThreadTile extends StatelessWidget {
  final ChatThreadModel thread;
  final ChatService chatService;
  final void Function(String otherUserId, String? otherUserName) onTap;

  const _ThreadTile({
    required this.thread,
    required this.chatService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return const SizedBox.shrink();
    }

    final otherId = chatService.getOtherParticipantId(thread, currentUid);
    final unread = thread.unreadCounts[currentUid] ?? 0;

    return FutureBuilder<Map<String, dynamic>?>(
      future: chatService.getUserPublicProfile(otherId),
      builder: (context, snap) {
        final p = snap.data;
        final name = (p?['name'] as String?)?.trim();
        final age = (p?['age'] as num?)?.toInt();
        final archetype = p?['archetype'] as String?;
        final category = p?['category'] as String?;
        final profilePhotoUrl = (p?['profile_photo_url'] as String?)?.trim();
        final photos = (p?['photos'] as List?)?.cast<String>() ?? const <String>[];

        final photoUrl = (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
            ? profilePhotoUrl
            : (photos.isNotEmpty ? photos.first : null);

        final displayName = (name == null || name.isEmpty) ? 'Conversation' : name;
        final subtitle = thread.lastMessagePreview?.trim().isNotEmpty == true
            ? thread.lastMessagePreview!.trim()
            : 'Say hi 👋';

        final timeText = _formatTimestamp(thread.lastMessageAt);

        return InkWell(
          onTap: () => onTap(otherId, name),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _BlurAvatar(photoUrl: photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              age != null ? '$displayName, $age' : displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (timeText != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              timeText,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      if ((archetype != null && archetype.isNotEmpty) ||
                          (category != null && category.isNotEmpty))
                        Text(
                          [
                            if (archetype != null && archetype.isNotEmpty) archetype,
                            if (category != null && category.isNotEmpty) category,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String? _formatTimestamp(Timestamp? ts) {
    if (ts == null) return null;
    final d = ts.toDate();
    final now = DateTime.now();
    final sameDay = now.year == d.year && now.month == d.month && now.day == d.day;
    if (sameDay) {
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }
}

class _BlurAvatar extends StatelessWidget {
  final String? photoUrl;

  const _BlurAvatar({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Icon(
        Icons.person,
        color: AppColors.primary.withValues(alpha: 0.6),
      ),
    );

    if (photoUrl == null || photoUrl!.isEmpty) return placeholder;

    return ClipOval(
      child: SizedBox(
        width: 52,
        height: 52,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        ),
      ),
    );
  }
}
