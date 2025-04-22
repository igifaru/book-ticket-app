import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _format = DateFormat('EEE, MMM d, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String format(DateTime date) {
    return _format.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return '${format(dateTime)} at ${formatTime(dateTime)}';
  }
} 