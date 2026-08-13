/// Visibility helpers for closed-account chat history (`closed_account_chat_history_ui_v1`).
library;

import '../models/chat_thread_model.dart';

/// Threads closed because a participant requested account deletion.
class ClosedAccountChatHistory {
  ClosedAccountChatHistory._();

  static const String closedReasonAccountDeletion = 'account_deletion_requested';
  static const String policyVersion = 'closed_account_chat_history_ui_v1';

  /// Whether this thread should appear in the Messages inbox.
  ///
  /// Active threads always appear. Closed threads appear **only** when
  /// [ChatThreadModel.closedReason] is [closedReasonAccountDeletion].
  /// Other closed reasons (unmatch/block) stay hidden unless product changes.
  static bool includeInMessagesList(ChatThreadModel thread) {
    if (thread.status == ThreadStatus.active) return true;
    return isAccountDeletionClosed(thread);
  }

  /// True when closed specifically for account deletion.
  static bool isAccountDeletionClosed(ChatThreadModel thread) {
    return thread.status == ThreadStatus.closed &&
        thread.closedReason == closedReasonAccountDeletion;
  }

  /// History may be streamed for active and deletion-closed threads.
  static bool allowMessageHistoryRead(ChatThreadModel thread) {
    return includeInMessagesList(thread);
  }

  /// Composer / send must stay off for deletion-closed threads.
  static bool allowSend(ChatThreadModel thread) {
    return thread.status == ThreadStatus.active;
  }
}
