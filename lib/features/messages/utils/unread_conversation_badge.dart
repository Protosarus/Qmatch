import '../models/chat_thread_model.dart';

/// Tab-badge math: count conversations with unread messages for [currentUid].
///
/// Does not read `messages/*`. Uses the existing `unread_counts` map only.
int unreadConversationCount({
  required Iterable<ChatThreadModel> threads,
  required String? currentUid,
}) {
  if (currentUid == null || currentUid.isEmpty) return 0;
  var n = 0;
  for (final thread in threads) {
    final count = thread.unreadCounts[currentUid] ?? 0;
    if (count > 0) n++;
  }
  return n;
}

/// Compact tab label. `null` means do not paint a badge.
String? unreadConversationBadgeLabel(int unreadConversations) {
  if (unreadConversations <= 0) return null;
  if (unreadConversations > 9) return '9+';
  return '$unreadConversations';
}
