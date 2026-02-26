// lib/providers/rate_store.dart
// Mutable currency rates for bulk update. Exchange dashboard reads from here.

import 'package:decimal/decimal.dart';
import 'mock_data.dart';

class RateStore {
  RateStore._();
  static final RateStore _instance = RateStore._();
  static RateStore get instance => _instance;

  /// code -> (buyRate, sellRate). Empty means use MockDataProvider defaults.
  final Map<String, ({Decimal buy, Decimal sell})> _rates = {};

  List<MockCurrencyRate> getRates() {
    final base = MockDataProvider.getCurrencyRates();
    return base.map((r) {
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
  }

  void setRates(Map<String, ({Decimal buy, Decimal sell})> rates) {
    _rates.clear();
    _rates.addAll(rates);
  }

  void setRate(String code, Decimal buy, Decimal sell) {
    _rates[code] = (buy: buy, sell: sell);
  }
}
