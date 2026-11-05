import 'package:intl/intl.dart';

/// Short, friendly time such as "2 hours ago". Older dates show the day.
String timeAgo(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(date);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) {
    return difference.inHours == 1
        ? '1 hour ago'
        : '${difference.inHours} hours ago';
  }
  if (difference.inDays < 7) {
    return difference.inDays == 1
        ? '1 day ago'
        : '${difference.inDays} days ago';
  }
  return DateFormat('MMM d, yyyy').format(date);
}
