import 'package:intl/intl.dart';

String? getFormattedTimestamp(DateTime? lastMessageDateTime, DateTime thisMessageDateTime) {
  final now = DateTime.now();

  // If there's no last message (e.g., the first message), show the full date and time
  if (lastMessageDateTime == null) {
    return null;
  }
  Duration diff = thisMessageDateTime.difference(lastMessageDateTime);
  Duration nowDiff = now.difference(thisMessageDateTime);
  if (diff.inMinutes < 30) {
    return null;
  } else {
    if (now.day == thisMessageDateTime.day && nowDiff.inHours < 24) {
      return DateFormat('h:mma').format(thisMessageDateTime);
    } else if (now.day - thisMessageDateTime.day == 1 && now.month == thisMessageDateTime.month && now.year == thisMessageDateTime.year) {
      // Same month and year, and exactly one day apart
      return 'Yesterday ${DateFormat('h:mma').format(thisMessageDateTime)}';
    } else if (nowDiff.inHours < 48 && now.day != thisMessageDateTime.day) {
      // Handles cases crossing months or years, still yesterday
      DateTime yesterday = now.subtract(Duration(days: 1));
      if (thisMessageDateTime.day == yesterday.day && thisMessageDateTime.month == yesterday.month && thisMessageDateTime.year == yesterday.year) {
        return 'Yesterday ${DateFormat('h:mma').format(thisMessageDateTime)}';
      }
    } else if (now.difference(thisMessageDateTime).inDays < 5 && nowDiff.inHours >= 24) {
      return DateFormat('E MMM d').format(thisMessageDateTime);
    } else if (thisMessageDateTime.year == now.year) {
      return "${DateFormat('MMM d').format(thisMessageDateTime)} at ${DateFormat('h:mma').format(thisMessageDateTime)}";
    } else {
      return DateFormat('MMM d, yyyy').format(thisMessageDateTime);
    }
  }
  return null;
}

String? getFormattedFirstTimestamp(DateTime? messageDateTime) {
  final now = DateTime.now();

  // If there's no last message (e.g., the first message), show the full date and time
  if (messageDateTime == null) {
    return null;
  }

  Duration nowDiff = now.difference(messageDateTime);
  if (now.day == messageDateTime.day && nowDiff.inHours < 24) {
    return DateFormat('h:mma').format(messageDateTime);
  } else if (now.day - messageDateTime.day == 1 && now.month == messageDateTime.month && now.year == messageDateTime.year) {
    // Same month and year, and exactly one day apart
    return 'Yesterday ${DateFormat('h:mma').format(messageDateTime)}';
  } else if (nowDiff.inHours < 48 && now.day != messageDateTime.day) {
    // Handles cases crossing months or years, still yesterday
    DateTime yesterday = now.subtract(Duration(days: 1));
    if (messageDateTime.day == yesterday.day && messageDateTime.month == yesterday.month && messageDateTime.year == yesterday.year) {
      return 'Yesterday ${DateFormat('h:mma').format(messageDateTime)}';
    }
  } else if (now.difference(messageDateTime).inDays < 5 && nowDiff.inHours >= 24) {
    return DateFormat('E MMM d').format(messageDateTime);
  } else if (messageDateTime.year == now.year) {
    return "${DateFormat('MMM d').format(messageDateTime)} at ${DateFormat('h:mma').format(messageDateTime)}";
  } else {
    return DateFormat('MMM d, yyyy').format(messageDateTime);
  }

  return null;
}
