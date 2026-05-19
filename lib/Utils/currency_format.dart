import 'package:intl/intl.dart';

class CurrencyFormat {
  /// Formats a number to Vietnamese currency format (e.g., 28.990.000 ₫)
  static String format(num value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }
}
