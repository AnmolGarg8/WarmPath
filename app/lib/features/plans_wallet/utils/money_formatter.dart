/// Money formatting utilities for Indian Rupees (Rs X,XXX) using intl.
/// Owner: M4
library;

import 'package:intl/intl.dart';

/// Formats a numerical amount in Indian Rupees using the Indian numbering system
/// and the rupee symbol (Rs 1,200, not $1,200 or 1200 INR).
/// Displays decimals only when the amount has paise.
String formatInr(num amount) {
  final hasPaise = (amount % 1) != 0;
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: hasPaise ? 2 : 0,
  );
  return formatter.format(amount).trim();
}

/// Formats duration in minutes to human-readable window (e.g. "48 hours", "2 minutes").
String formatWindowMinutes(int minutes) {
  if (minutes <= 0) return '0 minutes';
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return '$hours ${hours == 1 ? 'hour' : 'hours'}';
  } else {
    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  }
}
