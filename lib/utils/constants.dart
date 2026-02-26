// lib/utils/constants.dart

class AppConstants {
  // App Info
  static const String appName = 'Financial Services';
  static const String version = '1.0.0';
  
  // Base Currency
  static const String baseCurrency = 'MYR';
  
  // Supported Currencies (USD split into Big / Medium / Small denominations)
  static const List<Map<String, String>> supportedCurrencies = [
    {'code': 'USD_BIG', 'name': 'USD (Big)', 'flag': '🇺🇸'},
    {'code': 'USD_MED', 'name': 'USD (Medium)', 'flag': '🇺🇸'},
    {'code': 'USD_SML', 'name': 'USD (Small)', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound', 'flag': '🇬🇧'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'flag': '🇦🇺'},
    {'code': 'THB', 'name': 'Thailand Baht', 'flag': '🇹🇭'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'flag': '🇯🇵'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'flag': '🇸🇦'},
    {'code': 'AED', 'name': 'UAE Dirham', 'flag': '🇦🇪'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'flag': '🇨🇳'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'flag': '🇭🇰'},
    {'code': 'BND', 'name': 'Brunei Dollar', 'flag': '🇧🇳'},
    {'code': 'VND', 'name': 'Vietnamese Dong', 'flag': '🇻🇳'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'flag': '🇮🇩'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'flag': '🇸🇬'},
    {'code': 'INR', 'name': 'Indian Rupee', 'flag': '🇮🇳'},
  ];

  /// Decimal places for rate display: IDR uses 6 (e.g. 0.000285), others 4.
  static int rateDecimalsFor(String currencyCode) =>
      currencyCode == 'IDR' ? 6 : 4;
  
  // Tour Drivers
  static const List<String> drivers = ['Mahen', 'Others'];
  
  // Remittance Countries
  static const List<String> remittanceCountries = ['India', 'Indonesia'];
  
  // Default Values
  static const double defaultMarginAdjustment = 0.10;
  static const String defaultAutoSoldTime = '17:00';
  
  // Storage Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyAdminId = 'admin_id';
  static const String keyAdminEmail = 'admin_email';
}
