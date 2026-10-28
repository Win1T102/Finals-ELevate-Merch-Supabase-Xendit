import 'package:intl/intl.dart';

final NumberFormat _peso = NumberFormat.currency(
  locale: 'en_PH',
  symbol: '₱',
  decimalDigits: 2,
);

/// `₱1,250.00`
String formatPeso(num amount) => _peso.format(amount);

/// `₱1,250` for whole amounts, `₱1,250.50` otherwise.
String formatPesoShort(num amount) {
  if (amount == amount.roundToDouble()) {
    return NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    ).format(amount);
  }
  return formatPeso(amount);
}

/// `Oct 23, 2026 at 2:05 PM`
String formatOrderDate(DateTime date) {
  final local = date.toLocal();
  return DateFormat("MMM d, yyyy 'at' h:mm a").format(local);
}

/// `Oct 23, 2026`
String formatShortDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date.toLocal());
}

/// `2 items`, `1 item`
String formatItemCount(int count) => count == 1 ? '1 item' : '$count items';
