// lib/utils/formatters.dart

import 'package:intl/intl.dart';
import 'package:decimal/decimal.dart';

class AppFormatters {
  // Currency formatter
  static String formatCurrency(Decimal amount, {String symbol = 'MYR'}) {
    final formatter = NumberFormat('#,##0.00');
    return '$symbol ${formatter.format(amount.toDouble())}';
  }
  
  // Date formatter
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
  
  // DateTime formatter
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  // Precise date & time log (with seconds)
  static String formatDateTimePrecise(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm:ss').format(date);
  }
  
  // Time formatter
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
  
  // Number formatter
  static String formatNumber(double number, {int decimals = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}');
    return formatter.format(number);
  }
  
  // Decimal to string with fixed decimals
  static String decimalToString(Decimal value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  /// Rate display: IDR 6 decimals (0.000285), others 4.
  static String formatRate(Decimal rate, String currencyCode) {
    final decimals = currencyCode == 'IDR' ? 6 : 4;
    return rate.toStringAsFixed(decimals);
  }
}
