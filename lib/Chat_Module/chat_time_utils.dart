import 'package:cloud_firestore/cloud_firestore.dart';

DateTime chatDateTimeFrom(Object? value) {
  if (value is Timestamp) return value.toDate().toLocal();
  if (value is DateTime) return value.toLocal();
  if (value is num && value.isFinite) {
    final timestamp = value.toInt();
    final magnitude = timestamp.abs();
    if (magnitude >= 100000000000000) {
      return DateTime.fromMicrosecondsSinceEpoch(timestamp);
    }
    if (magnitude >= 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
  }
  return DateTime.now();
}

String formatChatTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String formatConversationTime(DateTime lastMessage, DateTime now) {
  final messageDay =
      DateTime(lastMessage.year, lastMessage.month, lastMessage.day);
  final today = DateTime(now.year, now.month, now.day);
  if (messageDay == today) return formatChatTime(lastMessage);
  if (messageDay == today.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  }
  return '${lastMessage.day}/${lastMessage.month}/${lastMessage.year}';
}
