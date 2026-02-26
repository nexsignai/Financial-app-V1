// lib/providers/rate_store.dart
// Mutable currency rates for bulk update. Exchange dashboard reads from here.
// Supports custom currencies persisted locally.

import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_data.dart';

const String _keyCustomRates = 'custom_currency_rates';

class RateStore {
  RateStore._();
  static final RateStore _instance = RateStore._();
  static RateStore get instance => _instance;

  /// code -> (buyRate, sellRate). Empty means use MockDataProvider defaults.
  final Map<String, ({Decimal buy, Decimal sell})> _rates = {};

  /// User-added custom currencies (persisted to SharedPreferences).
  final List<MockCurrencyRate> _customRates = [];

  /// Load custom rates from SharedPreferences. Call once before first getRates() (e.g. from dashboard).
  Future<void> loadCustomFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyCustomRates);
    _customRates.clear();
    if (json == null || json.isEmpty) return;
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      if (list == null) return;
      for (final e in list) {
        final map = e as Map<String, dynamic>;
        final code = map['code'] as String? ?? '';
        if (code.isEmpty) continue;
        _customRates.add(MockCurrencyRate(
          code: code,
          name: map['name'] as String? ?? code,
          flagEmoji: map['flagEmoji'] as String? ?? '🌐',
          realRate: Decimal.parse(map['realRate']?.toString() ?? '0'),
          displayBuyRate: Decimal.parse(map['displayBuyRate']?.toString() ?? '0'),
          displaySellRate: Decimal.parse(map['displaySellRate']?.toString() ?? '0'),
          isManualOverride: true,
          lastUpdated: DateTime.tryParse(map['lastUpdated']?.toString() ?? '') ?? DateTime.now(),
          averageCost: Decimal.parse(map['averageCost']?.toString() ?? '0'),
          currentInventory: Decimal.parse(map['currentInventory']?.toString() ?? '0'),
        ));
      }
    } catch (_) {}
  }

  Future<void> _saveCustomToPrefs() async {
    final list = _customRates.map((r) => {
      'code': r.code,
      'name': r.name,
      'flagEmoji': r.flagEmoji,
      'realRate': r.realRate.toString(),
      'displayBuyRate': r.displayBuyRate.toString(),
      'displaySellRate': r.displaySellRate.toString(),
      'lastUpdated': r.lastUpdated.toIso8601String(),
      'averageCost': r.averageCost.toString(),
      'currentInventory': r.currentInventory.toString(),
    }).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomRates, jsonEncode(list));
  }

  List<MockCurrencyRate> getRates() {
    final base = MockDataProvider.getCurrencyRates();
    final fromBase = base.map((r) {
      final over = _rates[r.code];
      if (over != null) {
        return MockCurrencyRate(
          code: r.code,
          name: r.name,
          flagEmoji: r.flagEmoji,
          realRate: r.realRate,
          displayBuyRate: over.buy,
          displaySellRate: over.sell,
          isManualOverride: true,
          lastUpdated: DateTime.now(),
          averageCost: r.averageCost,
          currentInventory: r.currentInventory,
        );
      }
      return r;
    }).toList();
    return [...fromBase, ..._customRates];
  }

  void setRates(Map<String, ({Decimal buy, Decimal sell})> rates) {
    _rates.clear();
    _rates.addAll(rates);
  }

  void setRate(String code, Decimal buy, Decimal sell) {
    _rates[code] = (buy: buy, sell: sell);
  }

  /// Add a custom currency (name, amount as initial inventory, buy/sell rates). Available to sell later.
  Future<void> addCustomRate({
    required String code,
    required String name,
    required Decimal initialAmount,
    required Decimal buyRate,
    required Decimal sellRate,
  }) async {
    final existing = MockDataProvider.getCurrencyRates().any((r) => r.code == code) ||
        _customRates.any((r) => r.code == code);
    if (existing) throw Exception('Currency code already exists: $code');
    final now = DateTime.now();
    _customRates.add(MockCurrencyRate(
      code: code,
      name: name,
      flagEmoji: '🌐',
      realRate: buyRate,
      displayBuyRate: buyRate,
      displaySellRate: sellRate,
      isManualOverride: true,
      lastUpdated: now,
      averageCost: buyRate,
      currentInventory: initialAmount,
    ));
    await _saveCustomToPrefs();
  }

  /// Remove a custom currency by code.
  Future<void> removeCustomRate(String code) async {
    _customRates.removeWhere((r) => r.code == code);
    await _saveCustomToPrefs();
  }

  bool isCustomCode(String code) =>
      _customRates.any((r) => r.code == code);
}
