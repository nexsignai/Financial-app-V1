// lib/services/supabase_history_service.dart
// Persists and loads all history and cash flow (opening cash) from Supabase.

import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/history_store.dart';

class SupabaseHistoryService {
  static SupabaseClient get _client => Supabase.instance.client;

  static const _tableRemittance = 'remittance_transactions';
  static const _tableExchange = 'exchange_transactions';
  static const _tableTour = 'tour_transactions';
  static const _tableDailySold = 'daily_sold_profits';
  static const _tableSettings = 'app_settings';
  static const _keyOpeningCash = 'opening_cash';

  static String _toIso(DateTime d) => d.toUtc().toIso8601String();

  static DateTime _fromIso(String? s) {
    if (s == null || s.isEmpty) return DateTime.now();
    return DateTime.parse(s).toLocal();
  }

  static String _dec(dynamic v) => v?.toString() ?? '0';

  // ---- Load all ----

  static Future<List<MockRemittanceEntry>> loadRemittance() async {
    final res = await _client.from(_tableRemittance).select().order('date_time', ascending: false);
    final list = res as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return MockRemittanceEntry(
        id: m['id'] as String? ?? '',
        dateTime: _fromIso(m['date_time'] as String?),
        customerName: m['customer_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        bankName: m['bank_name'] as String? ?? '',
        accountNumber: m['account_number'] as String? ?? '',
        myrAmount: Decimal.parse(_dec(m['myr_amount'])),
        foreignAmount: Decimal.parse(_dec(m['foreign_amount'])),
        currency: m['currency'] as String? ?? '',
        feeAmount: Decimal.parse(_dec(m['fee_amount'])),
        isPaid: m['is_paid'] as bool? ?? false,
        exchangeRate: Decimal.parse(_dec(m['exchange_rate'])),
        fixedRate: Decimal.parse(_dec(m['fixed_rate'])),
        costAmount: Decimal.parse(_dec(m['cost_amount'])),
        profitAmount: Decimal.parse(_dec(m['profit_amount'])),
      );
    }).toList();
  }

  static Future<List<MockExchangeEntry>> loadExchange() async {
    final res = await _client.from(_tableExchange).select().order('date_time', ascending: false);
    final list = res as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return MockExchangeEntry(
        id: m['id'] as String? ?? '',
        dateTime: _fromIso(m['date_time'] as String?),
        currency: m['currency'] as String? ?? '',
        mode: m['mode'] as String? ?? 'sell',
        foreignAmount: Decimal.parse(_dec(m['foreign_amount'])),
        myrAmount: Decimal.parse(_dec(m['myr_amount'])),
        rateUsed: Decimal.parse(_dec(m['rate_used'])),
      );
    }).toList();
  }

  static Future<List<MockTourEntry>> loadTour() async {
    final res = await _client.from(_tableTour).select().order('date_time', ascending: false);
    final list = res as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return MockTourEntry(
        id: m['id'] as String? ?? '',
        dateTime: _fromIso(m['date_time'] as String?),
        description: m['description'] as String? ?? '',
        driver: m['driver'] as String? ?? '',
        chargeAmount: Decimal.parse(_dec(m['charge_amount'])),
        profitAmount: Decimal.parse(_dec(m['profit_amount'])),
        isClear: m['is_clear'] as bool? ?? false,
      );
    }).toList();
  }

  static Future<List<DailySoldProfitEntry>> loadDailySoldProfits() async {
    final res = await _client.from(_tableDailySold).select().order('date_time', ascending: false);
    final list = res as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return DailySoldProfitEntry(
        id: m['id'] as String? ?? '',
        dateTime: _fromIso(m['date_time'] as String?),
        amount: Decimal.parse(_dec(m['amount'])),
      );
    }).toList();
  }

  static Future<Decimal> loadOpeningCash() async {
    final res = await _client.from(_tableSettings).select('value').eq('key', _keyOpeningCash).maybeSingle();
    final v = res?['value'] as String?;
    if (v != null && v.isNotEmpty) return Decimal.parse(v);
    return Decimal.parse('10000.00');
  }

  // ---- Save (upsert) ----

  static Future<void> saveRemittance(MockRemittanceEntry e) async {
    await _client.from(_tableRemittance).upsert({
      'id': e.id,
      'date_time': _toIso(e.dateTime),
      'customer_name': e.customerName,
      'phone': e.phone,
      'bank_name': e.bankName,
      'account_number': e.accountNumber,
      'myr_amount': e.myrAmount.toString(),
      'foreign_amount': e.foreignAmount.toString(),
      'currency': e.currency,
      'fee_amount': e.feeAmount.toString(),
      'is_paid': e.isPaid,
      'exchange_rate': e.exchangeRate.toString(),
      'fixed_rate': e.fixedRate.toString(),
      'cost_amount': e.costAmount.toString(),
      'profit_amount': e.profitAmount.toString(),
    });
  }

  static Future<void> saveExchange(MockExchangeEntry e) async {
    await _client.from(_tableExchange).upsert({
      'id': e.id,
      'date_time': _toIso(e.dateTime),
      'currency': e.currency,
      'mode': e.mode,
      'foreign_amount': e.foreignAmount.toString(),
      'myr_amount': e.myrAmount.toString(),
      'rate_used': e.rateUsed.toString(),
    });
  }

  static Future<void> saveTour(MockTourEntry e) async {
    await _client.from(_tableTour).upsert({
      'id': e.id,
      'date_time': _toIso(e.dateTime),
      'description': e.description,
      'driver': e.driver,
      'charge_amount': e.chargeAmount.toString(),
      'profit_amount': e.profitAmount.toString(),
      'is_clear': e.isClear,
    });
  }

  static Future<void> saveDailySoldProfit(DailySoldProfitEntry e) async {
    await _client.from(_tableDailySold).insert({
      'id': e.id,
      'date_time': _toIso(e.dateTime),
      'amount': e.amount.toString(),
    });
  }

  static Future<void> saveOpeningCash(Decimal value) async {
    await _client.from(_tableSettings).upsert({
      'key': _keyOpeningCash,
      'value': value.toString(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ---- Delete (removes from Supabase so history/profit/cash flow stay in sync) ----

  static Future<void> deleteRemittance(String id) async {
    await _client.from(_tableRemittance).delete().eq('id', id);
  }

  static Future<void> deleteExchange(String id) async {
    await _client.from(_tableExchange).delete().eq('id', id);
  }

  static Future<void> deleteTour(String id) async {
    await _client.from(_tableTour).delete().eq('id', id);
  }
}
