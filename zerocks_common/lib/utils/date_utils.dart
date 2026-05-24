/// Date and time utility functions used across all Zerocks apps.
class ZDateUtils {
  ZDateUtils._();

  /// Format a duration as a human-readable string.
  /// Examples: "2 min", "1 hr 30 min", "Just now"
  static String formatDuration(Duration duration) {
    if (duration.inSeconds < 60) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes} min';
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }

  /// Format a timestamp as relative time.
  /// Examples: "Just now", "5 min ago", "2 hours ago", "Yesterday", "May 23"
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  /// Format time as HH:mm (24-hour).
  static String formatTime24(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format as "May 23, 2026 at 14:30"
  static String formatFull(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, '
        '${dateTime.year} at ${formatTime24(dateTime)}';
  }

  /// Check if a DateTime is today.
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Get the start of today (midnight).
  static DateTime startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Calculate expiry time: input + hours.
  static DateTime expiresIn(DateTime from, {int hours = 24}) {
    return from.add(Duration(hours: hours));
  }
}
