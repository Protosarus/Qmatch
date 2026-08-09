import '../models/message_model.dart';

/// Presentation-only clock time for a chat bubble.
///
/// Prefers server [MessageModel.createdAt], then [MessageModel.clientCreatedAt].
/// Returns null when neither is available (pending / missing).
String? formatChatMessageTime(MessageModel message) {
  final ts = message.createdAt;
  if (ts != null) {
    return _hhmm(ts.toDate());
  }
  final ms = message.clientCreatedAt;
  if (ms == null) return null;
  return _hhmm(DateTime.fromMillisecondsSinceEpoch(ms));
}

/// Local calendar day for date separators (null if no usable timestamp).
DateTime? messageLocalDay(MessageModel message) {
  final ts = message.createdAt;
  if (ts != null) {
    final d = ts.toDate();
    return DateTime(d.year, d.month, d.day);
  }
  final ms = message.clientCreatedAt;
  if (ms == null) return null;
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day);
}

/// Compact numeric date for separators (deterministic; no intl).
String formatChatDateCompact(
  DateTime day, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final dd = day.day.toString().padLeft(2, '0');
  final mm = day.month.toString().padLeft(2, '0');
  if (day.year == reference.year) {
    return '$dd.$mm';
  }
  return '$dd.$mm.${day.year}';
}

bool isSameLocalDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whether a date separator should appear before [index] in [messages].
bool shouldShowChatDateSeparator(
  List<MessageModel> messages,
  int index,
) {
  if (index < 0 || index >= messages.length) return false;
  final currentDay = messageLocalDay(messages[index]);
  if (currentDay == null) return false;
  if (index == 0) return true;
  final previousDay = messageLocalDay(messages[index - 1]);
  if (previousDay == null) return true;
  return previousDay != currentDay;
}

String _hhmm(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
