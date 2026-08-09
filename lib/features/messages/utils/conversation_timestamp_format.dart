import 'package:cloud_firestore/cloud_firestore.dart';

/// Presentation-only timestamp formatting for Messages inbox rows.
///
/// Does not write or mutate Firestore values. Avoids locale-data init so
/// unit tests and offline goldens stay deterministic.
String? formatConversationTimestamp(
  Timestamp? timestamp, {
  DateTime? now,
  String? localeCode,
}) {
  if (timestamp == null) return null;

  final date = timestamp.toDate();
  final reference = now ?? DateTime.now();
  final sameDay = reference.year == date.year &&
      reference.month == date.month &&
      reference.day == date.day;

  if (sameDay) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  // Compact day.month — matches prior Messages inbox behavior.
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  return '$dd.$mm';
}
