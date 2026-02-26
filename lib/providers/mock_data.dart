// lib/providers/mock_data.dart

import 'package:decimal/decimal.dart';

class MockCurrencyRate {
  final String code;
  final String name;
  final String flagEmoji;
  final Decimal realRate;
  final Decimal displayBuyRate;
  final Decimal displaySellRate;
  final bool isManualOverride;
  final DateTime lastUpdated;
  final Decimal averageCost;
  final Decimal currentInventory;

  MockCurrencyRate({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.realRate,
    required this.displayBuyRate,
    required this.displaySellRate,
    this.isManualOverride = false,
    required this.lastUpdated,
    required this.averageCost,
    required this.currentInventory,
  });
}

class MockDataProvider {
  static List<MockCurrencyRate> getCurrencyRates() {
    final now = DateTime.now();
    
    return [
      MockCurrencyRate(
        code: 'USD_BIG',
        name: 'USD (Big)',
        flagEmoji: '🇺🇸',
        realRate: Decimal.parse('4.50'),
        displayBuyRate: Decimal.parse('4.38'),
        displaySellRate: Decimal.parse('4.62'),
        lastUpdated: now,
        averageCost: Decimal.parse('4.45'),
        currentInventory: Decimal.parse('2000.00'),
      ),
      MockCurrencyRate(
        code: 'USD_MED',
        name: 'USD (Medium)',
        flagEmoji: '🇺🇸',
        realRate: Decimal.parse('4.48'),
        displayBuyRate: Decimal.parse('4.36'),
        displaySellRate: Decimal.parse('4.60'),
        lastUpdated: now,
        averageCost: Decimal.parse('4.43'),
        currentInventory: Decimal.parse('1500.00'),
      ),
      MockCurrencyRate(
        code: 'USD_SML',
        name: 'USD (Small)',
        flagEmoji: '🇺🇸',
        realRate: Decimal.parse('4.46'),
        displayBuyRate: Decimal.parse('4.34'),
        displaySellRate: Decimal.parse('4.58'),
        lastUpdated: now,
        averageCost: Decimal.parse('4.41'),
        currentInventory: Decimal.parse('1000.00'),
      ),
      MockCurrencyRate(
        code: 'EUR',
        name: 'Euro',
        flagEmoji: '🇪🇺',
        realRate: Decimal.parse('4.90'),
        displayBuyRate: Decimal.parse('4.80'),
        displaySellRate: Decimal.parse('5.00'),
        lastUpdated: now,
        averageCost: Decimal.parse('4.85'),
        currentInventory: Decimal.parse('3000.00'),
      ),
      MockCurrencyRate(
        code: 'GBP',
        name: 'British Pound',
        flagEmoji: '🇬🇧',
        realRate: Decimal.parse('5.70'),
        displayBuyRate: Decimal.parse('5.60'),
        displaySellRate: Decimal.parse('5.80'),
        lastUpdated: now,
        averageCost: Decimal.parse('5.65'),
        currentInventory: Decimal.parse('2000.00'),
      ),
      MockCurrencyRate(
        code: 'AUD',
        name: 'Australian Dollar',
        flagEmoji: '🇦🇺',
        realRate: Decimal.parse('2.90'),
        displayBuyRate: Decimal.parse('2.80'),
        displaySellRate: Decimal.parse('3.00'),
        lastUpdated: now,
        averageCost: Decimal.parse('2.85'),
        currentInventory: Decimal.parse('4000.00'),
      ),
      MockCurrencyRate(
        code: 'THB',
        name: 'Thailand Baht',
        flagEmoji: '🇹🇭',
        realRate: Decimal.parse('0.13'),
        displayBuyRate: Decimal.parse('0.12'),
        displaySellRate: Decimal.parse('0.14'),
        lastUpdated: now,
        averageCost: Decimal.parse('0.13'),
        currentInventory: Decimal.parse('50000.00'),
      ),
      MockCurrencyRate(
        code: 'JPY',
        name: 'Japanese Yen',
        flagEmoji: '🇯🇵',
        realRate: Decimal.parse('0.030'),
        displayBuyRate: Decimal.parse('0.029'),
        displaySellRate: Decimal.parse('0.031'),
        lastUpdated: now,
        averageCost: Decimal.parse('0.030'),
        currentInventory: Decimal.parse('100000.00'),
      ),
      MockCurrencyRate(
        code: 'SAR',
        name: 'Saudi Riyal',
        flagEmoji: '🇸🇦',
        realRate: Decimal.parse('1.20'),
        displayBuyRate: Decimal.parse('1.10'),
        displaySellRate: Decimal.parse('1.30'),
        lastUpdated: now,
        averageCost: Decimal.parse('1.15'),
        currentInventory: Decimal.parse('8000.00'),
      ),
      MockCurrencyRate(
        code: 'AED',
        name: 'UAE Dirham',
        flagEmoji: '🇦🇪',
        realRate: Decimal.parse('1.23'),
        displayBuyRate: Decimal.parse('1.13'),
        displaySellRate: Decimal.parse('1.33'),
        lastUpdated: now,
        averageCost: Decimal.parse('1.18'),
        currentInventory: Decimal.parse('7000.00'),
      ),
      MockCurrencyRate(
        code: 'CNY',
        name: 'Chinese Yuan',
        flagEmoji: '🇨🇳',
        realRate: Decimal.parse('0.62'),
        displayBuyRate: Decimal.parse('0.60'),
        displaySellRate: Decimal.parse('0.64'),
        lastUpdated: now,
        averageCost: Decimal.parse('0.61'),
        currentInventory: Decimal.parse('15000.00'),
      ),
      MockCurrencyRate(
        code: 'HKD',
        name: 'Hong Kong Dollar',
        flagEmoji: '🇭🇰',
        realRate: Decimal.parse('0.58'),
        displayBuyRate: Decimal.parse('0.56'),
        displaySellRate: Decimal.parse('0.60'),
        lastUpdated: now,
        averageCost: Decimal.parse('0.57'),
        currentInventory: Decimal.parse('12000.00'),
      ),
      MockCurrencyRate(
        code: 'BND',
        name: 'Brunei Dollar',
        flagEmoji: '🇧🇳',
        realRate: Decimal.parse('3.50'),
        displayBuyRate: Decimal.parse('3.40'),
        displaySellRate: Decimal.parse('3.60'),
        lastUpdated: now,
        averageCost: Decimal.parse('3.45'),
        currentInventory: Decimal.parse('5000.00'),
      ),
      MockCurrencyRate(
        code: 'VND',
        name: 'Vietnamese Dong',
        flagEmoji: '🇻🇳',
        realRate: Decimal.parse('0.00018'),
        displayBuyRate: Decimal.parse('0.00017'),
        displaySellRate: Decimal.parse('0.00019'),
        lastUpdated: now,
        averageCost: Decimal.parse('0.00018'),
        currentInventory: Decimal.parse('50000000.00'),
      ),
      MockCurrencyRate(
        code: 'IDR',
        name: 'Indonesian Rupiah',
        flagEmoji: '🇮🇩',
        realRate: Decimal.parse('0.000285'),
        displayBuyRate: Decimal.parse('0.000275'),
        displaySellRate: Decimal.parse('0.000295'),
        lastUpdated: now,
        averageCost: Decimal.parse('0.000285'),
        currentInventory: Decimal.parse('100000.00'),
      ),
      MockCurrencyRate(
        code: 'SGD',
        name: 'Singapore Dollar',
        flagEmoji: '🇸🇬',
        realRate: Decimal.parse('3.35'),
        displayBuyRate: Decimal.parse('3.25'),
        displaySellRate: Decimal.parse('3.45'),
        lastUpdated: now,
        averageCost: Decimal.parse('3.30'),
        currentInventory: Decimal.parse('10000.00'),
      ),
      MockCurrencyRate(
        code: 'INR',
        name: 'Indian Rupee',
        flagEmoji: '🇮🇳',
        realRate: Decimal.parse('0.054'),
        displayBuyRate: Decimal.parse('0.053'),
        displaySellRate: Decimal.parse('0.055'),
        lastUpdated: now,
        averageCost: Decimal.parse('0.054'),
        currentInventory: Decimal.parse('50000.00'),
      ),
    ];
  }
  
  static List<MockCustomer> getCustomers() {
    final now = DateTime.now();
    
    return [
      MockCustomer(
        id: '1',
        name: 'Rajesh Kumar',
        phone: '+60123456789',
        bankName: 'ICICI Bank',
        accountNumber: '123456789012',
        ifscCode: 'ICIC0001234',
        country: 'India',
        createdAt: now.subtract(const Duration(days: 30)),
        lastTransactionDate: now.subtract(const Duration(days: 2)),
        totalTransactions: 5,
      ),
      MockCustomer(
        id: '2',
        name: 'Priya Sharma',
        phone: '+60198765432',
        bankName: 'HDFC Bank',
        accountNumber: '987654321098',
        ifscCode: 'HDFC0005678',
        country: 'India',
        createdAt: now.subtract(const Duration(days: 60)),
        lastTransactionDate: now.subtract(const Duration(days: 5)),
        totalTransactions: 3,
      ),
      MockCustomer(
        id: '3',
        name: 'Budi Santoso',
        phone: '+60187654321',
        bankName: 'Bank Mandiri',
        accountNumber: '1234567890',
        ifscCode: null,
        country: 'Indonesia',
        createdAt: now.subtract(const Duration(days: 45)),
        lastTransactionDate: now.subtract(const Duration(days: 1)),
        totalTransactions: 8,
      ),
    ];
  }
}

class MockCustomer {
  final String id;
  final String name;
  final String phone;
  final String bankName;
  final String accountNumber;
  final String? ifscCode;
  final String country;
  final DateTime createdAt;
  final DateTime? lastTransactionDate;
  final int totalTransactions;

  MockCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.bankName,
    required this.accountNumber,
    this.ifscCode,
    required this.country,
    required this.createdAt,
    this.lastTransactionDate,
    required this.totalTransactions,
  });
  
  String get currencyCode {
    return country == 'India' ? 'INR' : 'IDR';
  }
  
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        phone.contains(query) ||
        accountNumber.contains(query);
  }
}
