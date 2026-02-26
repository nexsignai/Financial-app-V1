import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import '../models/currency_rate.dart';

class RateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // List of supported currencies (USD split into Big/Medium/Small)
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

  /// Fetch real-time rates from external API
  /// NOTE: Replace with actual API endpoint
  Future<Map<String, Decimal>> fetchRealTimeRates() async {
    try {
      // PLACEHOLDER: Replace with actual API call
      // Example: Using exchangerate-api.com (free tier available)
      // final response = await http.get(
      //   Uri.parse('https://api.exchangerate-api.com/v4/latest/MYR'),
      // );
      
      // For now, return mock rates (REPLACE IN PRODUCTION)
      return {
        'USD_BIG': Decimal.parse('4.50'),
        'USD_MED': Decimal.parse('4.48'),
        'USD_SML': Decimal.parse('4.46'),
        'EUR': Decimal.parse('4.90'),
        'GBP': Decimal.parse('5.70'),
        'AUD': Decimal.parse('2.90'),
        'THB': Decimal.parse('0.13'),
        'JPY': Decimal.parse('0.030'),
        'SAR': Decimal.parse('1.20'),
        'AED': Decimal.parse('1.23'),
        'CNY': Decimal.parse('0.62'),
        'HKD': Decimal.parse('0.58'),
        'BND': Decimal.parse('3.50'),
        'VND': Decimal.parse('0.00018'),
        'IDR': Decimal.parse('0.000285'),
        'SGD': Decimal.parse('3.35'),
        'INR': Decimal.parse('0.054'),
      };
    } catch (e) {
      throw Exception('Failed to fetch real-time rates: $e');
    }
  }

  /// Update currency rates in Firestore
  Future<void> updateCurrencyRates() async {
    try {
      // Get global settings for margin
      final settingsDoc = await _firestore
          .collection('settings')
          .doc('global_settings')
          .get();
      
      final marginAdjustment = Decimal.parse(
        settingsDoc.data()?['marginAdjustment']?.toString() ?? '0.10',
      );
      
      final manualOverrides = settingsDoc.data()?['manualRateOverrides'] 
          as Map<String, dynamic>? ?? {};

      // Fetch real rates
      final realRates = await fetchRealTimeRates();
      
      final batch = _firestore.batch();
      
      for (final currency in supportedCurrencies) {
        final code = currency['code']!;
        final docRef = _firestore.collection('currency_rates').doc(code);
        
        // Check for manual override
        final hasManualOverride = manualOverrides[code] != null;
        final realRate = hasManualOverride
            ? Decimal.parse(manualOverrides[code].toString())
            : realRates[code] ?? Decimal.zero;
        
        // Calculate display rates
        final displayBuyRate = realRate - marginAdjustment;
        final displaySellRate = realRate + marginAdjustment;
        
        // Get existing data to preserve inventory
        final existingDoc = await docRef.get();
        final existingData = existingDoc.data();
        
        batch.set(docRef, {
          'code': code,
          'name': currency['name'],
          'flagEmoji': currency['flag'],
          'realRate': realRate.toDouble(),
          'displayBuyRate': displayBuyRate.toDouble(),
          'displaySellRate': displaySellRate.toDouble(),
          'isManualOverride': hasManualOverride,
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
          'averageCost': existingData?['averageCost'] ?? 0,
          'currentInventory': existingData?['currentInventory'] ?? 0,
          'lastSoldDate': existingData?['lastSoldDate'],
        }, SetOptions(merge: true));
      }
      
      await batch.commit();
      
      // Update last rate update timestamp
      await _firestore.collection('settings').doc('global_settings').update({
        'lastRateUpdate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update currency rates: $e');
    }
  }

  /// Set manual rate override for a currency
  Future<void> setManualRateOverride({
    required String currencyCode,
    required Decimal? rate,
  }) async {
    try {
      final settingsRef = _firestore.collection('settings').doc('global_settings');
      
      if (rate == null) {
        // Remove override
        await settingsRef.update({
          'manualRateOverrides.$currencyCode': FieldValue.delete(),
        });
      } else {
        // Set override
        await settingsRef.update({
          'manualRateOverrides.$currencyCode': rate.toDouble(),
        });
      }
      
      // Trigger rate update
      await updateCurrencyRates();
    } catch (e) {
      throw Exception('Failed to set manual rate override: $e');
    }
  }

  /// Get all currency rates
  Stream<List<CurrencyRate>> getAllRates() {
    return _firestore
        .collection('currency_rates')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CurrencyRate.fromFirestore(doc))
            .toList());
  }

  /// Get rate for specific currency
  Future<CurrencyRate?> getRate(String currencyCode) async {
    try {
      final doc = await _firestore
          .collection('currency_rates')
          .doc(currencyCode)
          .get();
      
      if (doc.exists) {
        return CurrencyRate.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get currency rate: $e');
    }
  }

  /// Update margin adjustment
  Future<void> updateMarginAdjustment(Decimal newMargin) async {
    try {
      await _firestore.collection('settings').doc('global_settings').update({
        'marginAdjustment': newMargin.toDouble(),
      });
      
      // Trigger rate update to recalculate display rates
      await updateCurrencyRates();
    } catch (e) {
      throw Exception('Failed to update margin: $e');
    }
  }

  /// Initialize default settings if they don't exist
  Future<void> initializeSettings() async {
    try {
      final settingsDoc = await _firestore
          .collection('settings')
          .doc('global_settings')
          .get();
      
      if (!settingsDoc.exists) {
        await _firestore.collection('settings').doc('global_settings').set({
          'baseCurrency': 'MYR',
          'marginAdjustment': 0.10,
          'lastRateUpdate': Timestamp.fromDate(DateTime.now()),
          'manualRateOverrides': {},
          'autoSoldTime': '17:00',
        });
        
        // Initialize currency rates
        await updateCurrencyRates();
      }
    } catch (e) {
      throw Exception('Failed to initialize settings: $e');
    }
  }
}
