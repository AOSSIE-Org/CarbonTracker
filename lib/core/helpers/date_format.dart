import 'package:intl/intl.dart';

String formatDate(int epochMillis) {
  final date = DateTime.fromMillisecondsSinceEpoch(epochMillis);
  return DateFormat('d MMM y').format(date);
}

String formatTime(int epochMillis) {
  final date = DateTime.fromMillisecondsSinceEpoch(epochMillis);
  return DateFormat('HH:mm').format(date);
}
